//
//  NRMAHarvestableTrace.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/12/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestableTrace.h"
#import "NRMAScopedMeasurement.h"
#import "NRMAScopedHTTPErrorMeasurement.h"
#import "NRMAScopedHTTPTransactionMeasurement.h"
@implementation NRMAHarvestableTrace
- (id) initWithTrace:(NRMATrace*)trace
{
    self = [super initWithSegmentType:@"trace"];
    if (self) {
        self.name = trace.name;
        self.startTime = (long long)trace.entryTimestamp;
        self.endTime = (long long)trace.exitTimestamp;
        self.threadInfo = trace.threadInfo;
        
        self.subSegments = [[NSMutableArray alloc] init];
        for (NRMATrace* subTrace in [trace.children allObjects]) {
            [self.subSegments addObject:[[NRMAHarvestableTrace alloc] initWithTrace:subTrace]];
        }
        self.events = [[NRMAScopedMeasurements alloc]initWithMeasurementType:NRMAMT_NamedEvent];
        self.network = [[NRMAScopedMeasurements alloc] initWithMeasurementType:NRMAMT_Network];

        for ( NRMAMeasurement* measurement in trace.scopedMeasurements) {
            if (measurement.type == NRMAMT_HTTPTransaction || measurement.type == NRMAMT_Network) {
                NRMAScopedMeasurement* scopedMeasurement = [[NRMAScopedHTTPTransactionMeasurement alloc] initWithMeasurement:measurement];
                scopedMeasurement.threadInfo = self.threadInfo;
                [self.network addScopedMeasurement:scopedMeasurement];
            } else if ( measurement.type == NRMAMT_HTTPError) {
                // error stuff.
                NRMAScopedMeasurement* scopedMeasurement = [[NRMAScopedHTTPErrorMeasurement alloc] initWithMeasurement:measurement];
                scopedMeasurement.threadInfo = self.threadInfo;
                [self.network addScopedMeasurement:scopedMeasurement];
            }  else if ( measurement.type == NRMAMT_NamedEvent) {
                [self.events addScopedMeasurement:[[NRMAScopedMeasurement alloc] initWithMeasurement:measurement]];
            }
            
        }
    }
    return self;
}

- (id) JSONObject
{
    NSMutableArray* array  = [super JSONObject];
    //thread info
    [array insertObject:@{@"type":@"TRACE"} atIndex:0];
    [array addObject:@[[NSNumber numberWithUnsignedInt:self.threadInfo.identity],[self.threadInfo.name length]?self.threadInfo.name:@""]];
    NSMutableArray* subSegments = [[NSMutableArray alloc] init];
    for (NRMAHarvestable* hObj in self.subSegments) {
        [subSegments addObject:[hObj JSONObject]];
    }
    
    if ([self.network count]) {
        [subSegments addObjectsFromArray:[self.network JSONObject]];
    }
    if ([self.events count]) {
        [subSegments addObjectsFromArray:[self.events JSONObject]];
    }
        
    [array addObject:subSegments];
    return array;
}
@end
