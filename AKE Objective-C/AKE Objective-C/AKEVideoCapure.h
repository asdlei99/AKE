//
//  AKEVideoCapure.h
//  AKE Objective-C
//
//  Created by akanchi on 2019/8/19.
//  Copyright © 2019 akanchi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVCaptureSession;
@class AKEPreviewView;

NS_ASSUME_NONNULL_BEGIN

@interface AKEVideoCapure : NSObject

@property (nonatomic, strong, readonly) AVCaptureSession *videoCaptureSession;

- (void)start:(AKEPreviewView *)previewView;
- (void)stop;
- (void)switchCamera;

@end

NS_ASSUME_NONNULL_END
