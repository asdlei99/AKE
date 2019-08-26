//
//  AKEPreviewView.h
//  AKE Objective-C
//
//  Created by akanchi on 2019/8/19.
//  Copyright © 2019 akanchi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCaptureSession;
@class AVCaptureVideoPreviewLayer;

NS_ASSUME_NONNULL_BEGIN

@interface AKEPreviewView : UIView

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (nonatomic, strong) AVCaptureSession *session;

@end

NS_ASSUME_NONNULL_END
