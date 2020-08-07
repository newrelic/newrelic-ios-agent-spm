//
//  NRMAMeasurementProducer.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/20/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMeasurementProducer.h"
#import "NRMAMeasurementException.h"
@implementation NRMAMeasurementProducer

- (void) dealloc
{
    self.producedMeasurements = nil;
}

- (id) initWithType:(NRMAMeasurementType)type
{

    self = [super init];
    if (self) {
        self.producedMeasurements = [[NSMutableDictionary alloc] init];
        _measurementType = type;
    }
    return self;
}

- (NRMAMeasurementType) measurementType
{
    return _measurementType;
}
- (void) setMeasurementType:(NRMAMeasurementType)type {
    _measurementType = type;
}
- (void) produceMeasurement:(NRMAMeasurement *)measurement
{
    @synchronized(self.producedMeasurements) {
        NSNumber* key = [NSNumber numberWithInt:measurement.type];
        NSMutableSet* typeSet = [self.producedMeasurements objectForKey:key];
        if (!typeSet) {
            typeSet = [NSMutableSet set];
            [self.producedMeasurements setObject:typeSet forKey:key];
        }
        [typeSet addObject:measurement];
    }
}

//this method expects a dictionary of  mutable sets.
- (void) produceMeasurements:(NSDictionary*)measurements
{
    @synchronized(self.producedMeasurements) {
        for (NSNumber* key in measurements.allKeys) {
            id value = [measurements objectForKey:key];
            if (value) {
                if ([self.producedMeasurements.allKeys containsObject:key]) {
                    [[self.producedMeasurements objectForKey:key] unionSet:value];
                } else {
                    [self.producedMeasurements setObject:value forKey:key];
                }
            }
        }
    }
}
- (NSDictionary*) drainMeasurements
{
    
    @synchronized(self.producedMeasurements) {
        NSDictionary* measurements = [[NSDictionary alloc] initWithDictionary:self.producedMeasurements];
        [self.producedMeasurements removeAllObjects];
        return measurements;
    }
}

@end
