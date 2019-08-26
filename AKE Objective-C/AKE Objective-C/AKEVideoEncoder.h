//
//  AKEVideoEncoder.h
//  AKE Objective-C
//
//  Created by akanchi on 2019/8/18.
//  Copyright © 2019 akanchi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AKEVideoEncoder : NSObject

- (int)encode:(CMSampleBufferRef)buffer;

@end

NS_ASSUME_NONNULL_END
