//
//  NRMAActivityTraces.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/13/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAActivityTraces.h"
#import "NRMAHarvestableActivity.h"
#import "NRMAHarvestableTrace.h"
#import "NRMAHarvestController.h"
#import "NRMAMeasurements.h"
#import "NRMAExceptionHandler.h"
#import "NRMATaskQueue.h"
#import "NRMAMetric.h"
@implementation NRMAActivityTraces
- (id) init
{
    self = [super initWithType:NRMA_HARVESTABLE_ARRAY];
    if (self) {
        self.activityTraces = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) addActivityTraces:(NRMAHarvestableActivity*) activity
{
    @synchronized(_activityTraces) {
        [self.activityTraces addObject:activity];
    }
}


- (void) clear
{
    @synchronized(_activityTraces) {
        [self.activityTraces removeAllObjects];
    }
}

- (int) count
{
    @synchronized(_activityTraces) {
        return (int)self.activityTraces.count;
    }
}

- (id) JSONObject
{
    NSMutableArray* array = [[NSMutableArray alloc] init];
    @synchronized(_activityTraces) {
        for (NRMAHarvestableActivity* activity in self.activityTraces) {
            NSError* error = nil;
            NSData* jsonData = [NRMAJSON dataWithJSONABLEObject:activity options:0 error:&error];
            if (jsonData.length >= [NRMAHarvestController configuration].activity_trace_max_size) {
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
                @try {
#endif
                    [NRMATaskQueue queue:[[NRMAMetric alloc] initWithName:kNRSupportabilityPrefix@"/BigActivityTracesDropped"
                                           value:[NSNumber numberWithInt:(int)jsonData.length]
                                       scope:@""]];
                    NRLOG_VERBOSE(@"Activity Trace JSON size limit exceeded. Skipping");
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
                } @catch (NSException* exception) {
                     [NRMAExceptionHandler logException:exception
                                                 class:NSStringFromClass([self class])
                                              selector:NSStringFromSelector(_cmd)];
                }
                #endif
            } else {
                [array addObject:[activity JSONObject]];
            }
        }
    }
    return array;
}

#pragma mark - NRMAHarvestAware methods
- (void) onHarvestBefore
{
    //remove old stuff
    NSMutableArray* removalArray = [[NSMutableArray alloc] init];
    NSTimeInterval currentTimeSec = [[NSDate date] timeIntervalSince1970];
    NRMAHarvesterConfiguration *config = [NRMAHarvestController configuration];
    NSTimeInterval oldestAllowedTraceAge = (currentTimeSec - config.report_max_transaction_age);
    int maxSendAttempts = config.activity_trace_max_send_attempts;

    @synchronized(_activityTraces) {
        for (NRMAHarvestableActivity* trace in self.activityTraces) {
            trace.sendAttempts++;
            if (trace.endTime < oldestAllowedTraceAge || trace.sendAttempts > maxSendAttempts) {
                [removalArray addObject:trace];
            }
        }
        if ([removalArray count]) {
            [self.activityTraces removeObjectsInArray:removalArray];
        }
    }
}

- (void)onHarvestError
{
    NSMutableArray *removalArray = [NSMutableArray array];
    int maxSendAttempts = [NRMAHarvestController configuration].activity_trace_max_send_attempts;

    @synchronized(_activityTraces) {
        for (NRMAHarvestableActivity* trace in self.activityTraces) {
            if (trace.sendAttempts >= maxSendAttempts) {
                [removalArray addObject:trace];
            }
        }
        if ([removalArray count]) {
            [self.activityTraces removeObjectsInArray:removalArray];
        }
    }
}

@end
