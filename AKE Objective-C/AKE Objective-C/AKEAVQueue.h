//
//  AKEAVQueue.h
//  AKE Objective-C
//
//  Created by akanchi on 2019/8/19.
//  Copyright © 2019 akanchi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AKEAVPacket;
@class AKEData;

NS_ASSUME_NONNULL_BEGIN

@interface AKEAVQueue : NSObject

+ (instancetype)sharedInstance;

- (void)enqueue:(AKEAVPacket *)packet;
- (NSArray<AKEAVPacket *> *)dequeue;

- (AKEAVPacket *)getUnEncodedVideo;
- (void)updatePacket:(AKEAVPacket *)packet data:(AKEData *)data;

@end

NS_ASSUME_NONNULL_END
