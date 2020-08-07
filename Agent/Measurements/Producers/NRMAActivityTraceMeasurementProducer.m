//
//  NRActivityTraceMeasurementProducer.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/11/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAActivityTraceMeasurementProducer.h"
#import "NRMAActivityTraceMeasurement.h"
#import "NRMAMeasurements.h"
#import "NRMAExceptionHandler.h"
#import "NRMATaskQueue.h"
#import "NRMAMetric.h"
@implementation NRMAActivityTraceMeasurementProducer

- (id) initWithType:(NRMAMeasurementType)type
{
    @throw [NRMAMeasurementException exceptionWithName:NRMAMeasurementTypeConsistencyError
                                              reason:@"Use -init to initialize NRActivityTraceMeasurementProducer"
                                            userInfo:nil];
}
- (id) init
{
    return [super initWithType:NRMAMT_Activity];
}
- (void) produceMeasurementWithTrace:(NRMAActivityTrace*)trace
{
    [NRMAMeasurements recordNetworkMetricsFromMetrics:trace.rootTrace.scopedMeasurements
                                          forActivity:trace.name];
    if (![trace shouldRecord]) {
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
        @try {
            #endif
            [NRMATaskQueue queue:[[NRMAMetric alloc] initWithName:kNRSupportabilityPrefix@"/IgnoredTraces"
                                                        value:@1
                                                    scope:nil]];
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
        } @catch (NSException* exception) {
            [NRMAExceptionHandler logException:exception
                                       class:NSStringFromClass([self class])
                                    selector:NSStringFromSelector(_cmd)];
        }
        #endif
        return;
    }
    NRMAActivityTraceMeasurement* traceMeasurement = [[NRMAActivityTraceMeasurement alloc] initWithActivityTrace:trace];
    [self produceMeasurement:traceMeasurement];
}
@end
