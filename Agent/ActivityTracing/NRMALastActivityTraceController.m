//
//  NRMALastActivityTraceController.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 7/8/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMALastActivityTraceController.h"

#import "NRLogger.h"

static NRMAInteractionDataStamp* __lastExecutedActivity;

static NSString const * kNRMALastExecutedActivityLock = @"lock";

@implementation NRMALastActivityTraceController
+ (void) storeLastActivityStampWithName:(NSString*)name
                         startTimestamp:(NSNumber*)timestampMillis
                               duration:(NSNumber*)durationMillis
{
    if (name == nil || timestampMillis == nil || durationMillis == nil) {
        NRLOG_VERBOSE(@"Attempted to store last activity with incomplete data.");
        return;
    }
    @synchronized(kNRMALastExecutedActivityLock) {
        if (__lastExecutedActivity == nil) {
            __lastExecutedActivity = [[NRMAInteractionDataStamp alloc] init];
        }
        __lastExecutedActivity.name = name;
        __lastExecutedActivity.startTimestamp = timestampMillis;
        __lastExecutedActivity.duration = durationMillis;
    }
}

+ (void) clearLastActivityStamp
{
    @synchronized(kNRMALastExecutedActivityLock) {
        __lastExecutedActivity = nil;
    }
}

+ (NRMAInteractionDataStamp*) copyLastActivityStamp
{
    @synchronized(kNRMALastExecutedActivityLock) {
        return [__lastExecutedActivity copy];
    }
}


#pragma mark - Unit Test Helpers

+ (NRMAInteractionDataStamp*) lastExecutedActivity
{
    return __lastExecutedActivity;
}

@end
