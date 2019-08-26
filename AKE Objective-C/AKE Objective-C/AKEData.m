//
//  AKEData.m
//  AKE Objective-C
//
//  Created by akanchi on 2019/8/19.
//  Copyright © 2019 akanchi. All rights reserved.
//

#import "AKEData.h"

@interface AKEData ()

@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, assign) NSUInteger pos;

@end

@implementation AKEData

- (instancetype)init {
    self = [super init];
    if (self) {
        _data = [NSMutableData data];
        _pos = 0;
    }

    return self;
}

#pragma mark - write
- (void)write_1byte:(int8_t)val {
    char *p = (char *)&val;
    [_data appendBytes:p length:1];
}

- (void)write_2bytes:(int16_t)val {
    char *p = (char *)&val;
    for (int i = 1; i >= 0; --i) {
        [_data appendBytes:p+i length:1];
    }
}

- (void)write_3bytes:(int32_t)val {
    char *p = (char *)&val;
    for (int i = 2; i >= 0; --i) {
        [_data appendBytes:p+i length:1];
    }
}

- (void)write_4bytes:(int32_t)val {
    char *p = (char *)&val;
    for (int i = 3; i >= 0; --i) {
        [_data appendBytes:p+i length:1];
    }
}

- (void)write_8bytes:(int64_t)val {
    char *p = (char *)&val;
    for (int i = 7; i >= 0; --i) {
        [_data appendBytes:p+i length:1];
    }
}

- (void)write_data:(NSData *)val {
    if (!val) {
        return;
    }

    [_data appendData:val];
}

- (void)write_pointer:(char *)p size:(NSUInteger)size {
    if (!p) {
        return;
    }

    [_data appendBytes:p length:size];
}

#pragma mark - read
- (int8_t)read_1byte {
    int8_t val = 0;
    char *p = (char *)&val;

    [_data getBytes:p range:NSMakeRange(_pos++, 1)];

    return val;
}

- (int16_t)read_2bytes {
    int16_t val = 0;
    char *p = (char *)&val;

    for (int i = 1; i >=0; --i) {
        [_data getBytes:p+i range:NSMakeRange(_pos++, 1)];
    }

    return val;
}

- (int32_t)read_3bytes {
    int32_t val = 0;
    char *p = (char *)&val;

    for (int i = 2; i >=0; --i) {
        [_data getBytes:p+i range:NSMakeRange(_pos++, 1)];
    }

    return val;
}

- (int32_t)read_4bytes {
    int32_t val = 0;
    char *p = (char *)&val;

    for (int i = 3; i >=0; --i) {
        [_data getBytes:p+i range:NSMakeRange(_pos++, 1)];
    }

    return val;
}

- (int64_t)read_8bytes {
    int32_t val = 0;
    char *p = (char *)&val;

    for (int i = 7; i >=0; --i) {
        [_data getBytes:p+i range:NSMakeRange(_pos++, 1)];
    }

    return val;
}

- (NSData *)read_data:(NSUInteger)size {
    NSData *val = nil;

    val = [_data subdataWithRange:NSMakeRange(_pos, size)];

    return val;
}

#pragma mark -
- (BOOL)empty {
    return _data.length == 0;
}

- (NSUInteger)size {
    return _data.length;
}

- (NSUInteger)pos {
    return _pos;
}

@end
