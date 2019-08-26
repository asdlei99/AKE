//
//  AKEAVPacket.h
//  AKE Objective-C
//
//  Created by akanchi on 2019/8/19.
//  Copyright © 2019 akanchi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AKEData;

NS_ASSUME_NONNULL_BEGIN

@interface AKEAVPacket : NSObject

@property (nonatomic, strong) AKEData *data;
@property (nonatomic, assign) uint8_t type;
@property (nonatomic, assign) uint64_t pts;
@property (nonatomic, assign) uint64_t dts;
@property (nonatomic, assign) BOOL hasEncoded;

@end

@interface AKEVideoPacket : AKEAVPacket

@end

@interface AKEAudioPacket : AKEAVPacket

@end

NS_ASSUME_NONNULL_END
