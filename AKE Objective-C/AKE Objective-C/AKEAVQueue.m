//
//  AKEAVQueue.m
//  AKE Objective-C
//
//  Created by akanchi on 2019/8/19.
//  Copyright © 2019 akanchi. All rights reserved.
//

#import "AKEAVQueue.h"
#import <pthread.h>
#import "AKEAVPacket.h"
#import <rtmp.h>

@interface AKEAVQueue ()

@property (nonatomic, strong) NSMutableArray<AKEAVPacket *> *queue;

@end

@implementation AKEAVQueue

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static AKEAVQueue *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[AKEAVQueue alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _queue = [NSMutableArray array];
    }

    return self;
}

- (void)dealloc {

}

- (void)enqueue:(AKEAVPacket *)packet {
    @synchronized (self) {
        [_queue addObject:packet];
    }
}

- (NSArray<AKEAVPacket *> *)dequeue {
    NSMutableArray<AKEAVPacket *> *packets = [NSMutableArray array];

    @synchronized (self) {
        for (AKEAVPacket *packet in _queue) {
            if (packet.hasEncoded) {
                [packets addObject:packet];
            }
        }

        if (packets.count > 0) {
            [_queue removeObjectsInArray:packets];
        }
    }

    return [packets copy];
}

- (AKEAVPacket *)getUnEncodedVideo {
    @synchronized (self) {
        for (AKEAVPacket *packet in _queue) {
            if (packet.type == RTMP_PACKET_TYPE_VIDEO && !packet.hasEncoded) {
                return packet;
            }
        }
    }

    return nil;
}

- (void)updatePacket:(AKEAVPacket *)packet data:(AKEData *)data{
    @synchronized (self) {
        packet.hasEncoded = YES;
        packet.data = data;
    }
}

@end
