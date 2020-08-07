//
//  NRMAMeasurementConsumer.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/20/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMeasurementConsumer.h"

@implementation NRMAMeasurementConsumer
- (id) initWithType:(NRMAMeasurementType)type
{
    self = [super init];
    if (self) {
        _measurementType = type;
    }
    return self;
}

- (NRMAMeasurementType) measurementType
{
    return _measurementType;
}

- (void) consumeMeasurement:(NRMAMeasurement *)measurement
{
}

- (void) consumeMeasurements:(NSDictionary*)measurements
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-selector-match"
    for (NSNumber* key in measurements.allKeys){
        for (NRMAMeasurement* measurement in [[measurements objectForKey:key] allObjects]) {
            [self consumeMeasurement:measurement];
        }
    }
#pragma clang diagnostic pop
}
@end
