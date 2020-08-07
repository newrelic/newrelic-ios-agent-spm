//
//  NRMAMetricSet.m
//  NewRelicAgent
//
//  Created by Jonathan Karon on 5/23/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <objc/runtime.h>

#import "NRMAMetricSet.h"
#import "NRLogger.h"
#import "NRMAHarvestableMetric.h"
#import "NRMAHarvestableMethodMetric.h"
#import "NRMAHarvestController.h"
#import "NewRelicInternalUtils.h"
@interface NRMAMetricSet ()
@property(strong) NSMutableDictionary* metrics;
@end

@implementation NRMAMetricSet

- (void) dealloc
{
    self.metrics = nil;
}
- (id)init
{
    self = [super initWithType:NRMA_HARVESTABLE_OBJECT];
    if (self) {
        self.metrics = [NSMutableDictionary new];
    }
    return self;
}

- (NSDictionary*) flushMetrics
{
    @synchronized(self) {
        NSDictionary* tmp = self.metrics;
        self.metrics = [NSMutableDictionary new];
        return tmp;
    }
}

- (void) addMetrics:(NRMAMetricSet*)metricSet
{
    @synchronized(self) {
        [self.metrics addEntriesFromDictionary:metricSet.metrics];
    }
}

- (void) addExclusiveTime:(NSNumber*)exclusiveTime
                forMetric:(NSString*)metricName
                withScope:(NSString*)scope
{
    scope = scope?:@"";
    @synchronized(self) {
        id obj = self.metrics[[NSString stringWithFormat:@"%@%@",scope,metricName]];
        if (![obj isKindOfClass:[NRMAHarvestableMethodMetric class]]) {
            obj = [[NRMAHarvestableMethodMetric alloc] initWithMetricName:metricName scope:scope];
            self.metrics[[NSString stringWithFormat:@"%@%@",scope,metricName]] = obj;
        }

        NRMAHarvestableMethodMetric* metric = ((NRMAHarvestableMethodMetric*)obj);
        [metric addExclusiveTime:exclusiveTime];
    }
}

- (void) addValue:(NSNumber *)value
        forMetric:(NSString *)metricName
        withScope:(NSString*)scope
{
    scope = scope?:@"";
    
    @synchronized(self) {
        NRMAHarvestableMetric *metric = self.metrics[[NSString stringWithFormat:@"%@%@",scope,metricName]];
        if (! metric) {
            NSRange methodRange = [metricName rangeOfString:@"Method/"];
            if (methodRange.location == 0) {
                //it's at the start of the string.
                metric = [[NRMAHarvestableMethodMetric alloc] initWithMetricName:metricName scope:scope];
            } else {
                metric = [[NRMAHarvestableMetric alloc] initWithMetricName:metricName scope:scope];
            }
            NSString* key = [NSString stringWithFormat:@"%@%@",scope,metricName];
            self.metrics[key] = metric;
        }
        [metric addValue:value];
    }
}


- (void)addValue:(NSNumber *)value forMetric:(NSString *)metricName
{
    if (!value) {
        NRLOG_WARNING(@"Attempting to add nil metric value.");
        return;
    }
    if (!metricName) {
        NRLOG_WARNING(@"Attempting to add nil metric name.");
        return;
    }
    [self addValue:value forMetric:metricName withScope:@""];
}

- (void)reset
{
    @synchronized (self) {
        [self.metrics removeAllObjects];
    };
}


- (id) JSONObject
{
    @synchronized(self) {
        NSMutableArray* output = [[NSMutableArray alloc] initWithCapacity:self.metrics.count];
        
        for (NSString *metricName in self.metrics) {
            NRMAHarvestableMetric *metric = self.metrics[metricName];
            [output addObject:[metric JSONObject]];
        }
        
        return output;
    }
}

- (NSUInteger) count
{
    @synchronized(self) {
        return self.metrics.count;
    }
}

- (void) removeMetricsWithAge:(NSTimeInterval)age
{
    @synchronized(self) {
        NSMutableArray* removalList = [[NSMutableArray alloc] init];
        long long currentTimeMillis = (long long)NRMAMillisecondTimestamp();
        for (NSString* key in [self.metrics allKeys]) {
            NRMAHarvestableMetric* metric = self.metrics[key];
            if (currentTimeMillis - [metric lastUpdatedMillis] > age*1000) {
                [removalList addObject:key];
            }
        }
        [self.metrics removeObjectsForKeys:removalList];
    }
}

- (void) trimToSize:(NSUInteger)count
{
    @synchronized(self) {
        NSArray* sortedKeys = [[self.metrics allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
            NRMAHarvestableMetric* metric1 = self.metrics[obj1];
            NRMAHarvestableMetric* metric2 = self.metrics[obj2];

            NSComparisonResult result = [@([metric1 lastUpdatedMillis]) compare:@([metric2 lastUpdatedMillis])];
            return result;
        }];

        NSArray* removeMeKeys = nil;
        if ([sortedKeys count] > count) {
            removeMeKeys = [sortedKeys subarrayWithRange:NSMakeRange(0, [sortedKeys count] - count)];
        }
        
        if ([removeMeKeys count]) {
            [self.metrics removeObjectsForKeys:removeMeKeys];
        }
    }
    
}
#pragma mark - NRMAHarvestAware methods

- (void) onHarvestBefore {
    [self removeMetricsWithAge:[@([NRMAHarvestController configuration].report_max_transaction_age) doubleValue]];
}
@end
