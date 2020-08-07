//
//  NRMAScopedMeasurements.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/26/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAScopedMeasurements.h"

@implementation NRMAScopedMeasurements
- (instancetype) initWithMeasurementType:(NRMAMeasurementType)type
{
    self = [super init];
    if (self) {
        self.measurements = [[NSMutableArray alloc] init];
        self.measurementType = type;
    }
    return self;
}
- (void) addScopedMeasurement:(NRMAScopedMeasurement*)measurement
{
    @synchronized(_measurements) {
        [self.measurements addObject:measurement];
    }
}

- (NSUInteger) count
{
    return [self.measurements count];
}
- (id) JSONObject
{   NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity:[self.measurements count]];
    for (NRMAScopedMeasurements* measurement in self.measurements)
        [array addObject:[measurement JSONObject]];
    
    return array;
}
@end
