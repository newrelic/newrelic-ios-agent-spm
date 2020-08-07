//
//  NRMAActivityTrace.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/6/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAActivityTrace.h"
#import "NRLogger.h"
#import "NRMACPUVitals.h"
#import "NRMAMeasurements.h"
#import "NRMAMemoryVitals.h"
#import "NewRelicInternalUtils.h"
#import "NRMAHarvestController.h"

#define RECORD_VITALS_THROTTLE_MS 100

@interface NRMAActivityTrace ()
{
    CPUTime _lastCPUTime;
    BOOL _lastCPUTimeValid;
    double _lastRecordVitalsTime;
}
@end
@implementation NRMAActivityTrace

- (id) initWithRootTrace:(NRMATrace *)rootTrace
{
    self = [super init];
    if (self) {
        self.name = @"MainActivity";
        self.lastUpdated = NRMAMillisecondTimestamp();
        
        self.rootTrace = rootTrace;
        self.startTime = NRMAMillisecondTimestamp();
        self.missingChildren = [[NSMutableSet alloc] init];
        
        self.isComplete = NO;
        self.traces = [[NSMutableDictionary alloc] init];
        self.memoryVitals = [[NSMutableDictionary alloc] init];
        self.cpuVitals = [[NSMutableDictionary alloc] init];
        
        _lastRecordVitalsTime = NRMAMillisecondTimestamp();
        int errorCode = [NRMACPUVitals cpuTime:&_lastCPUTime];
        _lastCPUTimeValid = (errorCode==0)?YES:NO;
    }
    return self;
}

- (void) addTrace:(NRMATrace *)trace
{
    @synchronized(_missingChildren) {
        [self.missingChildren addObject:trace];
    }
    self.nodes++;
    [self recordVitalsThrottled];
    self.lastUpdated = NRMAMillisecondTimestamp();
}

- (void)recordVitalsThrottled
{
    if (NRMAMillisecondTimestamp() - _lastRecordVitalsTime > RECORD_VITALS_THROTTLE_MS) {
        [self recordVitals];
    }

}

- (void)recordVitals
{
    NSTimeInterval now = NRMAMillisecondTimestamp();
    CPUTime cpuTime;
    double memoryUseInMegabytes, durationInSeconds;

    int errorCode = [NRMACPUVitals cpuTime:&cpuTime];
    memoryUseInMegabytes = [NRMAMemoryVitals memoryUseInMegabytes];
 
    durationInSeconds = (now - _lastRecordVitalsTime) / 1000.0;
    if (durationInSeconds == 0) {
        return;
    }

    if (errorCode == 0 && _lastCPUTimeValid) {
        double userUtilization = (cpuTime.utime - _lastCPUTime.utime) / durationInSeconds;

        @synchronized(_cpuVitals) {
            [self.cpuVitals setObject:[NSNumber numberWithDouble:userUtilization]
                               forKey:[NSNumber numberWithDouble:now]];
        }
        _lastRecordVitalsTime = now;
    }
    if (memoryUseInMegabytes != 0) {
        @synchronized(_memoryVitals) {
            [self.memoryVitals setObject:[NSNumber numberWithDouble:memoryUseInMegabytes]
                                forKey:[NSNumber numberWithDouble:now]];
        }
    }

    if (errorCode == 0) {
        _lastCPUTimeValid = YES;
        _lastCPUTime = cpuTime;
        _lastRecordVitalsTime = now;
    }

}

- (BOOL) hasMissingChildren
{
    @synchronized(_missingChildren) {
        return (BOOL)[self.missingChildren count];
    }
}

- (void) complete
{
//        //we want to do one final recordVitals, not throttled
//        //so it must be wrapped in thread safety block.
    [self recordVitals];

    self.endTime = self.lastUpdated;
    [NRMAMeasurements processCurrentSummaryMetricsWithTotalTime:self.endTime - self.startTime
                                                 activityName:self.name];
 //   [self.rootTrace calculateExclusiveTime];
    self.isComplete = YES;
}

- (NSTimeInterval) durationInSeconds
{
    return (self.endTime - self.startTime) / 1000;
}

- (BOOL) shouldRecord
{
    double exclusivePercentage = (self.totalExclusiveTimeMillis + self.totalNetworkTimeMillis) / (self.endTime - self.startTime);

    return exclusivePercentage > [NRMAHarvestController configuration].activity_trace_min_utilization;
}

@end
