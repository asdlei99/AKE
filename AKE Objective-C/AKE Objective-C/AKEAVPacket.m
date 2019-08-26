//
//  AKEAVPacket.m
//  AKE Objective-C
//
//  Created by akanchi on 2019/8/19.
//  Copyright © 2019 akanchi. All rights reserved.
//

#import "AKEAVPacket.h"
#import <rtmp.h>

@implementation AKEAVPacket

@end

@implementation AKEVideoPacket

- (instancetype)init {
    self = [super init];
    if (self) {
        self.type = RTMP_PACKET_TYPE_VIDEO;
    }

    return self;
}

@end

@implementation AKEAudioPacket

- (instancetype)init {
    self = [super init];
    if (self) {
        self.type = RTMP_PACKET_TYPE_AUDIO;
    }

    return self;
}

@end
