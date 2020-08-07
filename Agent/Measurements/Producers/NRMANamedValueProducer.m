//
//  NRMAMemoryMeasurementsProducer.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/30/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMANamedValueProducer.h"

#import "NRMANamedValueMeasurement.h"
#import "NRMAMemoryVitals.h"
@implementation NRMANamedValueProducer


- (instancetype) init
{
    self = [super initWithType:NRMAMT_NamedValue];
    if (self) {
        lastDataSendTimestamp = [NSDate timeIntervalSinceReferenceDate];
        int errorCode = [NRMACPUVitals appStartCPUtime:&lastCPUTime];
        lastCPUTimeIsValid = (errorCode == 0)?YES:NO;

    }
    return self;
}

- (void) generateMachineMeasurements
{
    NSMutableSet* machineMeasurementSet = [[NSMutableSet alloc] initWithCapacity:4];
    CPUTime currentCPUTime;

    int code = [NRMACPUVitals cpuTime:&currentCPUTime];

    if(code == 0 && lastCPUTimeIsValid) {
        NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - lastDataSendTimestamp;
        [machineMeasurementSet unionSet:[self generateCPUMeasurements:currentCPUTime withDuration:duration]];
    }

    double memoryUsage = [NRMAMemoryVitals memoryUseInMegabytes];

    if (memoryUsage != 0) {
       [machineMeasurementSet addObject:[[NRMANamedValueMeasurement alloc] initWithName:NRMA_METRIC_MEMORY_USAGE
                                                value:[NSNumber numberWithDouble:memoryUsage]]];

    }

    if (machineMeasurementSet != nil) {
        [self produceMeasurements:@{[NSNumber numberWithInt:NRMAMT_NamedValue]:machineMeasurementSet}];
    }


    if (code == 0) {
        lastCPUTime = currentCPUTime;
        lastCPUTimeIsValid = YES;
    }


}


- (void) onHarvestComplete
{
    lastDataSendTimestamp = [NSDate timeIntervalSinceReferenceDate];
}

- (NSMutableSet*) generateCPUMeasurements:(CPUTime)cpuTime withDuration:(NSTimeInterval)duration
{
    double userUtilization = (cpuTime.utime - lastCPUTime.utime) / duration;
    double systemUtilization = (cpuTime.stime - lastCPUTime.stime) / duration;
    double totalUtilization = userUtilization + systemUtilization;

    NSMutableSet *measurements = [[NSMutableSet alloc] initWithObjects:
                                  [[NRMANamedValueMeasurement alloc] initWithName:NRMA_METRIC_USER_CPU_TIME
                                                                          value:[NSNumber numberWithDouble:userUtilization]],
                                  [[NRMANamedValueMeasurement alloc] initWithName:NRMA_METRIC_SYSTEM_CPU_TIME
                                                                          value:[NSNumber numberWithDouble:systemUtilization]],
                                  [[NRMANamedValueMeasurement alloc] initWithName:NRMA_METRIC_TOTAL_CPU_TIME
                                                                          value:[NSNumber numberWithDouble:totalUtilization]],
                                  nil];

    return measurements;
}

@end
