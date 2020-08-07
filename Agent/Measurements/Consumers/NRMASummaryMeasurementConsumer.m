//
//  NRMASummaryMeasurementConsumer.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/31/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMASummaryMeasurementConsumer.h"
#import "NRMAHTTPTransactionMeasurement.h"
#import "NRMAMethodSummaryMeasurement.h"
#import "NRLogger.h"
#import "NRMAHarvestableMetric.h"
#import "NRMAMeasurements.h"
#import "NRMAExceptionHandler.h"
#import "NRMATaskQueue.h"
#import "NRMAMetric.h"
#define NRMAMeasurementMetricName @"Mobile/Summary"

@interface NRMASummaryMeasurementConsumer ()
@property(strong,atomic) NRMAMetricSet* summaryMeasurements;
@end

@implementation NRMASummaryMeasurementConsumer
- (instancetype) init
{
    self = [super initWithType:NRMAMT_Any];
    if (self){
        self.summaryMeasurements = [[NRMAMetricSet alloc] init];
    }
    return self;
}


- (void) consumeMeasurement:(NRMAMeasurement *)measurement
{
    switch (measurement.type) {
        case NRMAMT_Method:
            [self consumeMethodMeasurement:(NRMAMethodSummaryMeasurement*)measurement];
            break;
        case NRMAMT_HTTPTransaction:
            [self consumeHTTPMeasurement:(NRMAHTTPTransactionMeasurement*)measurement];
            break;
        default:
            break;
    }
}

- (void) consumeHTTPMeasurement:(NRMAHTTPTransactionMeasurement*) measurement
{
    [self.summaryMeasurements addValue:@(measurement.endTime - measurement.startTime)
                        forMetric:NSStringFromNRMATraceType(NRTraceTypeNetwork)];
}

- (void) consumeMethodMeasurement:(NRMAMethodSummaryMeasurement*)measurement
{
    if (measurement.category == NRTraceTypeNone) {
        return;
    }
    
    [self.summaryMeasurements addValue:@([measurement exclusiveTime])
                        forMetric:NSStringFromNRMATraceType(measurement.category)];
}

- (void) aggregateAndNormalizeAndRecordValuesWithTotalTime:(double)totalTimeMillis
                                            scope:(NSString*)scope
{


    double totalExclusiveTime = 0;
    NSDictionary* metricsDictionary = [self.summaryMeasurements flushMetrics];

    NSMutableDictionary* nonNormalizeCategoryValues = [[NSMutableDictionary alloc] initWithCapacity:self.summaryMeasurements.count];
    for (NSString* category in [metricsDictionary allKeys]) {
        NRMAHarvestableMetric* metric =  metricsDictionary[category];
        double exclusiveTimeSum = 0;
        for (NSDictionary* dict in [metric allValues]) {
            exclusiveTimeSum += [dict[@"value"] doubleValue];
        }
        nonNormalizeCategoryValues[category] = @(exclusiveTimeSum);
        totalExclusiveTime += exclusiveTimeSum;
    }
    
    if (totalExclusiveTime == 0) {
        NRLOG_VERBOSE(@"normalization error: totalExclusiveTime == 0. Not a big deal.");
        return;
    }
    
    for (NSString* category in nonNormalizeCategoryValues) {
        NSNumber* value = nonNormalizeCategoryValues[category];
        double normalizedValue = [value doubleValue] / totalExclusiveTime;
        
        NSString* metricName = [NSString stringWithFormat:@"%@/%@",NRMAMeasurementMetricName,category];
        
        NRLOG_VERBOSE(@"recording %@ to scope %@",metricName,scope);

#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
        @try {
            #endif
        [NRMATaskQueue queue:[[NRMAMetric alloc] initWithName:[NSString stringWithFormat:@"%@/%@",NRMAMeasurementMetricName,category]
                                value:@((normalizedValue*totalTimeMillis)/(double)1000)
                            scope:scope
                         produceUnscoped:YES]];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
        } @catch (NSException* exception) {
            [NRMAExceptionHandler logException:exception
                                       class:NSStringFromClass([self class])
                                    selector:NSStringFromSelector(_cmd)];
        }
        #endif
    }
}

@end
