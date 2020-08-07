//
//  NRMAHTTPErrorTraceGenerator.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/10/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMeasurementTransmitter.h"
#import "NRMAHTTPErrorMeasurement.h"
#import "NRMAActivityTrace.h"
@implementation NRMAMeasurementTransmitter
- (id) initWithType:(NRMAMeasurementType)type
    destinationPool:(NRMAMeasurementPool*)pool
{
    self = [super initWithType:type];
    if (self) {
        self.destinationPool = pool;
    }
    return self;
}

- (void) consumeMeasurement:(NRMAMeasurement *)measurement
{
    [self.destinationPool produceMeasurement:measurement];
    [self.destinationPool broadcastMeasurements];
}

- (void) consumeMeasurements:(NSDictionary *)measurements
{
    NSNumber* key = [NSNumber numberWithInt:_measurementType];
    NSSet*  measurementSet = [measurements objectForKey:key];
    if (![measurementSet count])
        return;
    
    [self.destinationPool produceMeasurements:@{key:measurementSet}];
    [self.destinationPool broadcastMeasurements];
}
@end
