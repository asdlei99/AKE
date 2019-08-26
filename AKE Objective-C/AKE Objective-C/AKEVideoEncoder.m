//
//  AKEVideoEncoder.m
//  AKE Objective-C
//
//  Created by akanchi on 2019/8/18.
//  Copyright © 2019 akanchi. All rights reserved.
//

#import "AKEVideoEncoder.h"
#import <VideoToolbox/VideoToolbox.h>
#import "AKEData.h"
#import "AKEAVQueue.h"
#import "AKEAVPacket.h"

//@see:https://mobisoftinfotech.com/resources/mguide/h264-encode-decode-using-videotoolbox/
@interface AKEVideoEncoder ()

@property (nonatomic, strong) dispatch_queue_t encodeQueue;
@property (nonatomic, unsafe_unretained) VTCompressionSessionRef encodeSession;

@property (nonatomic, assign) uint32_t width;
@property (nonatomic, assign) uint32_t height;

@property (nonatomic, strong) AKEData *videoSHData;

@end

@implementation AKEVideoEncoder

void CompressionOutputCallback(void * CM_NULLABLE outputCallbackRefCon, void * CM_NULLABLE sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CM_NULLABLE CMSampleBufferRef sampleBuffer) {
    // Check if there were any errors encoding
    if (status != noErr) {
        NSLog(@"Error encoding video, err=%lld", (int64_t)status);
        return;
    }

    AKEVideoEncoder *encoder = (__bridge AKEVideoEncoder*)outputCallbackRefCon;
    // Find out if the sample buffer contains an I-Frame.
    // If so we will write the SPS and PPS NAL units to the elementary stream.
    BOOL isIFrame = NO;
    CFArrayRef attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, 0);
    if (CFArrayGetCount(attachmentsArray)) {
        CFBooleanRef notSync;
        CFDictionaryRef dict = CFArrayGetValueAtIndex(attachmentsArray, 0);
        BOOL keyExists = CFDictionaryGetValueIfPresent(dict,
                                                       kCMSampleAttachmentKey_NotSync,
                                                       (const void **)&notSync);
        // An I-Frame is a sync frame
        isIFrame = !keyExists || !CFBooleanGetValue(notSync);
    }

    // Write the SPS and PPS NAL units to the elementary stream before every I-Frame
    if (isIFrame && !encoder.videoSHData) {
        CMFormatDescriptionRef description = CMSampleBufferGetFormatDescription(sampleBuffer);

        // Find out how many parameter sets there are
        size_t numberOfParameterSets;
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description,
                                                           0, NULL, NULL,
                                                           &numberOfParameterSets,
                                                           NULL);

        // Write each parameter set to the elementary stream
        AKEData *akeData = [AKEData new];
        for (int i = 0; i < numberOfParameterSets; i++) {
            const uint8_t *parameterSetPointer;
            size_t parameterSetLength;
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description,
                                                               i,
                                                               &parameterSetPointer,
                                                               &parameterSetLength,
                                                               NULL, NULL);

            // Write the parameter set to the elementary stream
            if (0 == i) {
                // sps
                [akeData write_1byte:0x17];
                [akeData write_4bytes:0x00];
                [akeData write_1byte:0x01];
                [akeData write_pointer:(char *)parameterSetPointer+1 size:3];
                [akeData write_1byte:0xff];
                [akeData write_1byte:0xe1];
                [akeData write_2bytes:parameterSetLength];
                [akeData write_pointer:(char *)parameterSetPointer size:(NSUInteger)parameterSetLength];
            } else if (1 == i) {
                // pps
                [akeData write_1byte:0x01];
                [akeData write_2bytes:parameterSetLength];
                [akeData write_pointer:(char *)parameterSetPointer size:(NSUInteger)parameterSetLength];
                break;
            }
        }
        encoder.videoSHData = akeData;
        AKEVideoPacket *packet = [AKEVideoPacket new];
        packet.hasEncoded = YES;
        packet.dts = 0;
        packet.data = akeData;
        [[AKEAVQueue sharedInstance] enqueue:packet];
    }

    size_t blockBufferLength;
    uint8_t *bufferDataPointer = NULL;
    status = CMBlockBufferGetDataPointer(CMSampleBufferGetDataBuffer(sampleBuffer),
                                0,
                                NULL,
                                &blockBufferLength,
                                (char **)&bufferDataPointer);

    if (status != noErr) {
        NSLog(@"fuck error!!");
        return;
    }

    AKEData *body = [AKEData new];
    [body write_1byte:isIFrame ? 0x17 : 0x27];
    [body write_1byte:0x01];
    [body write_3bytes:0];

    [body write_pointer:bufferDataPointer size:blockBufferLength];

    AKEAVPacket *packet = [[AKEAVQueue sharedInstance] getUnEncodedVideo];
    if (!packet) {
        return;
    }

    [[AKEAVQueue sharedInstance] updatePacket:packet data:body];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.encodeQueue = dispatch_queue_create("ake.h264.encode.queue", DISPATCH_QUEUE_SERIAL);
        self.width = 720;
        self.height = 1280;

        [self initEncoder];
    }

    return self;
}

- (void)initEncoder {
    dispatch_sync(self.encodeQueue, ^{
        OSStatus status = VTCompressionSessionCreate(NULL, self.width, self.height, kCMVideoCodecType_H264, NULL, NULL, NULL, CompressionOutputCallback, (__bridge void *)(self), &self->_encodeSession);

        if (status != 0) {
            NSLog(@"H264: Unable to create H264 session, status=%@", @(status));
            return;
        }

        VTSessionSetProperty(self.encodeSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        VTSessionSetProperty(self.encodeSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFNumberRef)@(20.0));
        VTSessionSetProperty(self.encodeSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Main_AutoLevel);

        VTCompressionSessionPrepareToEncodeFrames(self.encodeSession);
    });
}

- (int)encode:(CMSampleBufferRef)buffer {
    AKEAVPacket *packet = [[AKEAVQueue sharedInstance] getUnEncodedVideo];
    if (!packet) {
        return -1;
    }

    dispatch_sync(self.encodeQueue, ^{
        // Get the CV Image buffer
        CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(buffer);

        // Create properties
        CMTime presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(buffer);
        //CMTime duration = CMTimeMake(1, DURATION);
        VTEncodeInfoFlags flags;

        // Pass it to the encoder
        OSStatus statusCode = VTCompressionSessionEncodeFrame(self.encodeSession,
                                                              imageBuffer,
                                                              presentationTimeStamp,
                                                              kCMTimeInvalid,
                                                              NULL, NULL, &flags);

        // Check for error
        if (statusCode != noErr) {

            NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);

            // End the session
            VTCompressionSessionInvalidate(self.encodeSession);
            CFRelease(self.encodeSession);
            self.encodeSession = NULL;
            return;
        }
    });
    return 0;
}

@end
