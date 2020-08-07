//
//  NRMAHarvestableMethodMetric.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/8/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestableMethodMetric.h"

@implementation NRMAHarvestableMethodMetric

- (instancetype) initWithMetricName:(NSString *)name scope:(NSString *)scope
{
    self = [super initWithMetricName:name scope:scope];
    if (self) {
        self.exclusiveTimes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) addExclusiveTime:(NSNumber*)value
{
    [self.exclusiveTimes addObject:value];
}

- (id) JSONObject
{
    NSMutableArray* array = [super JSONObject];
    double totalExclusiveTime = 0;
    for (NSNumber* exclusiveTime in self.exclusiveTimes) {
        totalExclusiveTime += exclusiveTime.doubleValue;
    }
    
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithDictionary:[array objectAtIndex:1]];
    [dictionary setObject:[NSNumber numberWithDouble:totalExclusiveTime]
                   forKey:@"exclusive"];
    return [NSMutableArray arrayWithObjects:[array objectAtIndex:0],dictionary, nil];
}
@end
