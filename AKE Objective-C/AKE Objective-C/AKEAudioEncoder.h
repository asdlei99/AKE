//
//  AKEAudioEncoder.h
//  AKE Objective-C
//
//  Created by akanchi on 2019/8/20.
//  Copyright © 2019 akanchi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AKEAudioEncoder : NSObject

- (void)encode:(CMSampleBufferRef)buffer;

@end

NS_ASSUME_NONNULL_END
