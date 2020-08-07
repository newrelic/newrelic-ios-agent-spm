//
//  NRCustomMetrics+private.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 7/15/13.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRCustomMetrics.h"
#import "NRMAMetricSet.h"
@interface NRCustomMetrics (privateMethods)
/*
 * FUNCTION   : + (NRMAMetricSet*) metrics;
 * DISCUSSION : returns the set of metrics logged thus far
 *              (or since last harvest)
 */
+ (NRMAMetricSet*) metrics;

/*
 * FUNCTION   : + (NRMAMetricSet*) harvest
 * DISCUSSION : this function will return the existing metrics log upto this 
 *              point and reset the MetricSet to nil.
 */
+ (NRMAMetricSet*) harvest;


/* 
 * FUNCTION   : + (void) addMetric:(NSString*)metric value:(NSNumber*)value;
 * DISCUSSION : for internal use only. metric should be a fully formed metric string.
 *              can throw an exception (wrap in try-catch)
 */
+ (void) addMetric:(NSString*)metric
             value:(NSNumber*)value;
@end
