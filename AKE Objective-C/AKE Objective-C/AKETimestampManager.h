//
//  AKETimestampManager.h
//  AKE Objective-C
//
//  Created by akanchi on 2019/8/25.
//  Copyright © 2019 akanchi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AKETimestampManager : NSObject

+ (instancetype)sharedInstance;

- (uint64_t)audioTimestamp;
- (uint64_t)videoTimestamp;

@end

NS_ASSUME_NONNULL_END
