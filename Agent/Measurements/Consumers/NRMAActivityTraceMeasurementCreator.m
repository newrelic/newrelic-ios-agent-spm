//
//  NRMAActivityTraceMeasurementCreator.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/11/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAActivityTraceMeasurementCreator.h"
#import "NRMATraceSegment.h"
#import "NRMAHarvestableTrace.h"
#import "NRMAHarvestableActivity.h"
#import "NRMAHarvestableHTTPError.h"
#import "NRMAActivityTraces.h"
#import "NRMAActivityTraceMeasurement.h"
#import "NRMAAgentConfiguration.h"
#import "NRMAEnvironmentTraceSegment.h"
#import "NRMAHarvestController.h"
#import "NRMAMeasurements.h"

#import "NRMAHarvestableVitals.h"
@implementation NRMAActivityTraceMeasurementCreator

- (id) init
{
    self = [super initWithType:NRMAMT_Activity];
    if (self) {
        
    }
    
    return self;
}
- (void) consumeMeasurement:(NRMAMeasurement *)measurement {
    if (![measurement isKindOfClass:[NRMAActivityTraceMeasurement class]]) {
        return;
    }
    NRMAActivityTraceMeasurement* activityTrace = (NRMAActivityTraceMeasurement*)measurement;
    
    NRMAHarvestableActivity* harvestableActivity = [[NRMAHarvestableActivity  alloc] init];
    
    harvestableActivity.name = activityTrace.traceName;
    harvestableActivity.startTime = (long long)activityTrace.startTime;
    harvestableActivity.endTime = (long long)activityTrace.endTime;
    harvestableActivity.lastActivityStamp = [activityTrace.lastActivity JSONObject];

    [harvestableActivity.childSegments addObject:[[NRMAEnvironmentTraceSegment alloc] init]];
    
    [harvestableActivity.childSegments addObject:[[NRMAHarvestableTrace alloc] initWithTrace:activityTrace.rootTrace]];
    NRMAHarvestableVitals* vitals = nil;
    @synchronized(activityTrace.cpuVitals) {
        @synchronized(activityTrace.memoryVitals) {
        vitals = [[NRMAHarvestableVitals alloc] initWithCPUVitals:activityTrace.cpuVitals
                                                                    memoryVitals:activityTrace.memoryVitals];
        }
    }

    [harvestableActivity.childSegments addObject:vitals];

    [NRMAHarvestController addHarvestableActivity:harvestableActivity];
}
@end
