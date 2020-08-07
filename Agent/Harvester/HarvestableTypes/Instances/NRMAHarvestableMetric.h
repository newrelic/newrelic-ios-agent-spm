//
//  NRMAMetric.h
//  NewRelicAgent
//
//  Created by Jonathan Karon on 5/23/13.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAHarvestable.h"
#define kEndDateKey  @"endDate"
#define kValueKey    @"value"
@interface NRMAHarvestableMetric : NRMAHarvestable
{
    long long lastUpdateMillis;
}
@property (nonatomic, strong) NSString *metricName;

- (NSArray*) allValues;

/*
// * FUNCTION   : - (id)initWithMetricName:(NSString *)name scope:(NSString*)scope;
 * DISCUSSION :
 */
- (id)initWithMetricName:(NSString *)name
                   scope:(NSString*)scope;

- (id) initWithMetricName:(NSString*) name;

/*
 * FUNCTION   : - (void) incrementCount;
 * DISCUSSION : helper method, just calls addValue with a parameter of 1;
 */
 - (void) incrementCount;

/*
 * FUNCTION   : - (NSUInteger) count
 * DISCUSSION : returns the count of metric values contained
 */
- (NSUInteger) count;

/*
 * FUNCTION   : - (void) addValue:(NSNumber *)value;
 * DISCUSSION : inserts a new value into metric as well as captures an
 *              endDate and threadID for the value.
 */
- (void) addValue:(NSNumber *)value;


/*
 * FUNCTION   : - (void) reset;
 * DISCUSSION : remove all stored values
 */
- (void) reset;

/*
 * FUNCTION   : - (void) removeValuesWithAge:(NSTimeInterval)age;
 * DISCUSSION : removes all stored values older than age
 */
- (void) removeValuesWithAge:(NSTimeInterval)age;

/*
 * FUNCTION   : - (NSDate*) lastUpdated;
 * DISCUSSION : this will return the endDate of the most recently added value
 */
- (long long) lastUpdatedMillis;

/*
 * FUNCTION   : - (id) JSONObject;
 * DISCUSSION : calculates metric data points (min, max, avg, sos, etc) 
 *              and returns a JSON transformable dictionary for transmitting 
 *              to the collector.
 */
- (id) JSONObject;

@end
