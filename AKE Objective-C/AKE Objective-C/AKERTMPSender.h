//
//  AKERTMPSender.h
//  AKE Objective-C
//
//  Created by akanchi on 2019/8/18.
//  Copyright © 2019 akanchi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AKEData;

NS_ASSUME_NONNULL_BEGIN

@interface AKERTMPSender : NSObject

- (BOOL)connect;

- (void)sendPacket:(uint8_t)type data:(NSData *)data timestamp:(uint32_t)timestamp;


@end

NS_ASSUME_NONNULL_END
