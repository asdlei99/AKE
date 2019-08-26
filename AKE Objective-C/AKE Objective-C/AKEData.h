//
//  AKEData.h
//  AKE Objective-C
//
//  Created by akanchi on 2019/8/19.
//  Copyright © 2019 akanchi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AKEData : NSObject

#pragma mark - write
- (void)write_1byte:(int8_t)val;
- (void)write_2bytes:(int16_t)val;
- (void)write_3bytes:(int32_t)val;
- (void)write_4bytes:(int32_t)val;
- (void)write_8bytes:(int64_t)val;
- (void)write_data:(NSData *)val;
- (void)write_pointer:(char *)p size:(NSUInteger)size;

#pragma mark - read
- (int8_t)read_1byte;
- (int16_t)read_2bytes;
- (int32_t)read_3bytes;
- (int32_t)read_4bytes;
- (int64_t)read_8bytes;
- (NSData *)read_data:(NSUInteger)size;

#pragma mark -
- (BOOL)empty;
- (NSUInteger)size;
- (NSUInteger)pos;

@end

NS_ASSUME_NONNULL_END
