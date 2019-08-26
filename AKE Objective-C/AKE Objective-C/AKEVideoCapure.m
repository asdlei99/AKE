//
//  AKEVideoCapure.m
//  AKE Objective-C
//
//  Created by akanchi on 2019/8/19.
//  Copyright © 2019 akanchi. All rights reserved.
//

#import "AKEVideoCapure.h"
#import <AVFoundation/AVFoundation.h>
#import "AKEPreviewView.h"
#import "AKEVideoEncoder.h"
#import "AKERTMPSender.h"

//@see: https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avcam_building_a_camera_app?language=objc
@interface AKEVideoCapure ()
<
AVCaptureVideoDataOutputSampleBufferDelegate
>

@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) AVCaptureSession *videoCaptureSession;
@property (nonatomic, strong) AVCaptureDeviceDiscoverySession *videoDeviceDiscoverySession;
@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;

@property (nonatomic, strong) dispatch_queue_t sampleBufferCallbackQueue;

@property (nonatomic, strong) AKEVideoEncoder *videoEncoder;

@end

@implementation AKEVideoCapure

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sessionQueue = dispatch_queue_create("ake.video.capture.session.queue", DISPATCH_QUEUE_SERIAL);
        _sampleBufferCallbackQueue = dispatch_queue_create("ake.video.sample.buffer.callback.queue", DISPATCH_QUEUE_SERIAL);

        // Create a device discovery session.
        NSArray<AVCaptureDeviceType>* deviceTypes = @[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInDualCamera, AVCaptureDeviceTypeBuiltInTrueDepthCamera];
        self.videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];

        self.videoEncoder = [AKEVideoEncoder new];
    }

    return self;
}

- (void)start:(AKEPreviewView *)previewView
{
    if (self.videoCaptureSession) {
        return;
    }

    self.videoCaptureSession = [AVCaptureSession new];
    self.videoCaptureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    previewView.session = self.videoCaptureSession;

    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoDataOutput.videoSettings = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey: (id)kCVPixelBufferPixelFormatTypeKey];
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.sampleBufferCallbackQueue];

    dispatch_async(self.sessionQueue, ^{
        [self.videoCaptureSession beginConfiguration];

        AVCaptureDevice* videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
        if (!videoDevice) {
            // If a rear dual camera is not available, default to the rear wide angle camera.
            videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];

            // In the event that the rear wide angle camera isn't available, default to the front wide angle camera.
            if (!videoDevice) {
                videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
            }
        }

        NSError* error = nil;
        AVCaptureDeviceInput* videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        if (!videoDeviceInput) {
            NSLog(@"Could not create video device input: %@", error);
            [self.videoCaptureSession commitConfiguration];
            return;
        }
        self.videoDeviceInput = videoDeviceInput;
        if ([self.videoCaptureSession canAddInput:videoDeviceInput]) {
            [self.videoCaptureSession addInput:videoDeviceInput];
        }

        CMTime frameDuration = CMTimeMake(1, 20);
        NSArray *supportedFrameRateRanges = [self.videoDeviceInput.device.activeFormat videoSupportedFrameRateRanges];
        BOOL frameRateSupported = NO;
        for (AVFrameRateRange *range in supportedFrameRateRanges) {
            if (CMTIME_COMPARE_INLINE(frameDuration, >=, range.minFrameDuration) &&
                CMTIME_COMPARE_INLINE(frameDuration, <=, range.maxFrameDuration)) {
                frameRateSupported = YES;
            }
        }

        if (frameRateSupported && [self.videoDeviceInput.device lockForConfiguration:&error]) {
            [self.videoDeviceInput.device setActiveVideoMaxFrameDuration:frameDuration];
            [self.videoDeviceInput.device setActiveVideoMinFrameDuration:frameDuration];
            [self.videoDeviceInput.device unlockForConfiguration];
        }

        if ([self.videoCaptureSession canAddOutput:self.videoDataOutput]) {
            [self.videoCaptureSession addOutput:self.videoDataOutput];
        }

        AVCaptureConnection *captureConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([captureConnection isVideoOrientationSupported]) {
            captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }

        [self.videoCaptureSession commitConfiguration];
        [self.videoCaptureSession startRunning];
    });
}

- (void)stop
{
    [self.videoCaptureSession stopRunning];
}

- (void)switchCamera
{
    dispatch_async(self.sessionQueue, ^{
        AVCaptureDevice* currentVideoDevice = self.videoDeviceInput.device;
        AVCaptureDevicePosition currentPosition = currentVideoDevice.position;

        AVCaptureDevicePosition preferredPosition;
        AVCaptureDeviceType preferredDeviceType;

        switch (currentPosition)
        {
            case AVCaptureDevicePositionUnspecified:
            case AVCaptureDevicePositionFront:
                preferredPosition = AVCaptureDevicePositionBack;
                preferredDeviceType = AVCaptureDeviceTypeBuiltInDualCamera;
                break;
            case AVCaptureDevicePositionBack:
                preferredPosition = AVCaptureDevicePositionFront;
                preferredDeviceType = AVCaptureDeviceTypeBuiltInTrueDepthCamera;
                break;
        }

        NSArray<AVCaptureDevice* >* devices = self.videoDeviceDiscoverySession.devices;
        AVCaptureDevice* newVideoDevice = nil;

        // First, look for a device with both the preferred position and device type.
        for (AVCaptureDevice* device in devices) {
            if (device.position == preferredPosition && [device.deviceType isEqualToString:preferredDeviceType]) {
                newVideoDevice = device;
                break;
            }
        }

        // Otherwise, look for a device with only the preferred position.
        if (!newVideoDevice) {
            for (AVCaptureDevice* device in devices) {
                if (device.position == preferredPosition) {
                    newVideoDevice = device;
                    break;
                }
            }
        }

        if (newVideoDevice) {
            AVCaptureDeviceInput* videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:newVideoDevice error:NULL];

            [self.videoCaptureSession beginConfiguration];

            // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
            [self.videoCaptureSession removeInput:self.videoDeviceInput];

            if ([self.videoCaptureSession canAddInput:videoDeviceInput]) {
                [self.videoCaptureSession addInput:videoDeviceInput];
                self.videoDeviceInput = videoDeviceInput;
            } else {
                [self.videoCaptureSession addInput:self.videoDeviceInput];
            }

            AVCaptureConnection *captureConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
            if ([captureConnection isVideoOrientationSupported]) {
                captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
            }

            [self.videoCaptureSession commitConfiguration];
        }
    });
}

- (void)captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection
{
    [self.videoEncoder encode:sampleBuffer];
}

@end
