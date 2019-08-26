//
//  AKEAudioCapture.m
//  AKE Objective-C
//
//  Created by akanchi on 2019/8/20.
//  Copyright © 2019 akanchi. All rights reserved.
//

#import "AKEAudioCapture.h"
#import <AVFoundation/AVFoundation.h>
#import "AKEAudioEncoder.h"

@interface AKEAudioCapture ()
<
AVCaptureAudioDataOutputSampleBufferDelegate
>

@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) AVCaptureSession *audioCaptureSession;
@property (nonatomic, strong) AVCaptureDeviceDiscoverySession *audioDeviceDiscoverySession;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic, strong) dispatch_queue_t sampleBufferCallbackQueue;

@property (nonatomic, strong) AKEAudioEncoder *audioEncoder;

@end

@implementation AKEAudioCapture

- (instancetype)init {
    self = [super init];
    if (self) {
        _sessionQueue = dispatch_queue_create("ake.audio.capture.session.queue", DISPATCH_QUEUE_SERIAL);
        _sampleBufferCallbackQueue = dispatch_queue_create("ake.audio.sample.buffer.callback.queue", DISPATCH_QUEUE_SERIAL);
        // Create a device discovery session.
        NSArray<AVCaptureDeviceType>* deviceTypes = @[AVCaptureDeviceTypeBuiltInMicrophone];
        self.audioDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeAudio position:AVCaptureDevicePositionUnspecified];

        _audioEncoder = [AKEAudioEncoder new];
    }

    return self;
}

- (void)start {
    if (self.audioCaptureSession) {
        return;
    }

    self.audioCaptureSession = [AVCaptureSession new];

    self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioDataOutput setSampleBufferDelegate:self queue:self.sampleBufferCallbackQueue];

    dispatch_async(self.sessionQueue, ^{
        [self.audioCaptureSession beginConfiguration];

        AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        if (!audioDevice) {
            NSLog(@"Get audio device failed!");
            return;
        }

        NSError* error = nil;
        AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
        if (!audioDeviceInput) {
            NSLog(@"Could not create audio device input: %@", error);
            return;
        }

        if ([self.audioCaptureSession canAddInput:audioDeviceInput]) {
            [self.audioCaptureSession addInput:audioDeviceInput];
        }

        if ([self.audioCaptureSession canAddOutput:self.audioDataOutput]) {
            [self.audioCaptureSession addOutput:self.audioDataOutput];
        }

        [self.audioCaptureSession commitConfiguration];
        [self.audioCaptureSession startRunning];
    });
}

- (void)stop {

}

#pragma mark - AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    [_audioEncoder encode:sampleBuffer];
}

@end
