//
//  NRMAMachineMeasurementConsumer.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/30/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMachineMeasurementConsumer.h"
#import "NRMANamedValueMeasurement.h"
#import "NRMAMetricSet.h"
#import "NRMAHarvestableMetric.h"
#import "NRMAHarvestController.h"

@implementation NRMAMachineMeasurementConsumer
- (instancetype) init
{
    self = [super initWithType:NRMAMT_NamedValue];
    if (self) {
    }
    return self;
}

- (void) consumeMeasurement:(NRMAMeasurement *)measurement
{
    if ([measurement isKindOfClass:[NRMANamedValueMeasurement class]]) {
        [NRMAHarvestController addNamedValue:(NRMANamedValueMeasurement*)measurement];
    }
}

- (void) consumeMeasurements:(NSDictionary *)measurements
{
    NSSet* measurementSet = [measurements objectForKey:[NSNumber numberWithInt:self.measurementType]];
    for (NRMANamedValueMeasurement* measurement in measurementSet.allObjects) {
        [self consumeMeasurement:measurement];
    }
}
@end
