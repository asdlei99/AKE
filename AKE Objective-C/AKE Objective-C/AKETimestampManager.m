//
//  AKETimestampManager.m
//  AKE Objective-C
//
//  Created by akanchi on 2019/8/25.
//  Copyright © 2019 akanchi. All rights reserved.
//

#import "AKETimestampManager.h"
#import "AKEAVPacket.h"
#import "AKEAVQueue.h"

@interface AKETimestampManager ()

@property (nonatomic, assign) uint64_t audioTimestamp;
@property (nonatomic, assign) uint64_t videoTimestamp;

@property (nonatomic, assign) float videoTimeInterval;
@property (nonatomic, assign) float audioTimeInterval;

@end

@implementation AKETimestampManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static AKETimestampManager *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[AKETimestampManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _videoTimestamp = 0;
        _audioTimestamp = 0;
        _videoTimeInterval = 1000 / 20;
        _audioTimeInterval = 1024 * 1000 / 44100;
    }

    return self;
}

- (uint64_t)audioTimestamp {
    while ([self nextAudioTimestamp] >= [self nextVideoTimestamp]) {
        _videoTimestamp = [self nextVideoTimestamp];
        // TODO: pla
        AKEVideoPacket *packet = [AKEVideoPacket new];
        packet.hasEncoded = NO;
        packet.dts = _videoTimestamp;
        [[AKEAVQueue sharedInstance] enqueue:packet];
    }

    _audioTimestamp = [self nextAudioTimestamp];
    return _audioTimestamp;
}

- (uint64_t)videoTimestamp {
    return _videoTimestamp;
}

- (uint64_t)nextVideoTimestamp {
    return _videoTimestamp + _videoTimeInterval;
}

- (uint64_t)nextAudioTimestamp {
    return _audioTimestamp + _audioTimeInterval;
}

@end
