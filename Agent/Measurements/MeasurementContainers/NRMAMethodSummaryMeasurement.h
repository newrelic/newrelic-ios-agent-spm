//
//  NRMAMethodSummaryMeasurement.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/31/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//
#import "NRMACustomTrace.h"
#import "NRMAMeasurement.h"

@interface NRMAMethodSummaryMeasurement : NRMAMeasurement
{
    double  _exclusiveTime;
}

@property(nonatomic) enum NRTraceType category;
- (double) exclusiveTime;
- (instancetype) initWithName:(NSString*)name
                        scope:(NSString*)scope
                    startTime:(double)startTime
                      endtime:(double)endTime
                exclusiveTime:(double)exclusiveTime
                traceCategory:(enum NRTraceType)category;

@end
