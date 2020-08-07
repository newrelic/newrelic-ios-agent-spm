//
//  NRMAMethodSummaryMeasurement.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/31/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMethodSummaryMeasurement.h"

@implementation NRMAMethodSummaryMeasurement

- (instancetype) initWithName:(NSString*)name
                        scope:(NSString*)scope
                    startTime:(double)startTime
                      endtime:(double)endTime
                exclusiveTime:(double)exclusiveTime
                 traceCategory:(enum NRTraceType)category
{
    self = [super initWithType:NRMAMT_Method];
    if (self) {
        _name = name;
        [self setStartTime:startTime];
        [self setEndTime:endTime];
        _exclusiveTime = exclusiveTime;
        _category = category;
        
    }
    return self;
}

- (double) exclusiveTime
{
    return _exclusiveTime;
}
@end
