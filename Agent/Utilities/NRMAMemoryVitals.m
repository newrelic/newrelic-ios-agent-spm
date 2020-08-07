//
//  NRMAMemoryVitals.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/7/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAMemoryVitals.h"
#import <mach/mach.h>
#import "NRLogger.h"
#import "NewRelicInternalUtils.h"
#import "NRConstants.h"
#define BYTES_PER_MB            1048576.0
#define NRMAMemoryCacheDuration 1000
@implementation NRMAMemoryVitals
static NSString *__NRMAMemoryVitalsLock = @"NRMAMemoryVitalsLock";
static double __lastCachedMillis;
static double __lastCachedMemoryUsage;



//http://stackoverflow.com/questions/787160/programmatically-retrieve-memory-usage-on-iphone
+ (double) memoryUseInMegabytes {

    @synchronized(__NRMAMemoryVitalsLock) {
        double currentTime = NRMAMillisecondTimestamp();
        if (currentTime < __lastCachedMillis + NRMAMemoryCacheDuration ) {
            return __lastCachedMemoryUsage;
        }
        __lastCachedMillis = currentTime;

        struct mach_task_basic_info info;
        mach_msg_type_number_t size = MACH_TASK_BASIC_INFO_COUNT;
        kern_return_t kerr = task_info(mach_task_self(),
                                       MACH_TASK_BASIC_INFO,
                                       (task_info_t)&info,
                                       &size);
        if( kerr == KERN_SUCCESS ) {
            __lastCachedMemoryUsage = (float)info.resident_size / BYTES_PER_MB;
            [[NSNotificationCenter defaultCenter] postNotificationName:kNRMemoryUsageDidChangeNotification
                                                                object:@(__lastCachedMemoryUsage)];
            return __lastCachedMemoryUsage;
        } else {
            NRLOG_ERROR(@"Error with task_info(): %s", mach_error_string(kerr));
            return 0;
        }
    }
}

@end
