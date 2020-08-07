//
//  NRMAMetricSet.h
//  NewRelicAgent
//
//  Created by Jonathan Karon on 5/23/13.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAHarvestable.h"
#import "NRMAHarvestAware.h"
@interface NRMAMetricSet : NRMAHarvestable <NRMAHarvestAware>

- (void)addValue:(NSNumber *)value forMetric:(NSString *)metricName;
- (void) addValue:(NSNumber *)value
        forMetric:(NSString *)metricName
        withScope:(NSString*)scope;
- (void)reset;
- (void) addMetrics:(NRMAMetricSet*)metricSet;

- (void) addExclusiveTime:(NSNumber*)exclusiveTime
                forMetric:(NSString*)metricName
                withScope:(NSString*)scope;

- (id) JSONObject;

/*
 * FUNCTION   : - (void) trimToSize:(NSUInteger) count;
 * DISCUSSION : this will remove the oldest unique metics until the number of
 *              metrics are equal to count.
 */
- (void) trimToSize:(NSUInteger) count;


/*
 * FUNCTION   : - (void) removeMetricsWithAge:(NSTimeInterval)age;
 * DISCUSSION : will iterate through stored metrics and removed the recorded
 *              values older than age. if there are no values left the metric
 *              itself will also be removed.
 */
- (void) removeMetricsWithAge:(NSTimeInterval)age;

/*
 * FUNCTION   : - (NSUInteger) count;
 * DISCUSSION : returns the number of unique metrics stored in NRMAMetricSet
 */
- (NSUInteger) count;

- (NSDictionary*) flushMetrics;

@end
