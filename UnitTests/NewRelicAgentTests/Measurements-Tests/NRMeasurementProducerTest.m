//
//  MeasurementProducerTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/23/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMeasurementProducerTest.h"
@implementation NRMAMeasurementProducerTest


- (void) setUp
{
    producer = [[NRMAMeasurementProducer alloc] initWithType:NRMAMT_Method];
}
- (void) testGetProducedMeasurementType
{
    XCTAssertTrue(NRMAMT_Method == producer.type, @"");
}

- (void) testProduceMeasurement
{
    NRMAMeasurement* measurement = [[NRMAMeasurement alloc] initWithType:NRMAMT_Method];
    [producer produceMeasurement:measurement];
    NSDictionary* measurements = [producer drainMeasurements];
    XCTAssertTrue([measurements count] == 1, @"");
    XCTAssertTrue([[measurements objectForKey:[NSNumber numberWithInt:NRMAMT_Method]] containsObject:measurement], @"");

    XCTAssertTrue(0 == [producer drainMeasurements].count, @"producer shouldn't have any measurements after a drain");
 
    int numMeasurements = 1000;
    for(int i = 0; i < numMeasurements; i++) {
        [producer produceMeasurement:[[NRMAMeasurement alloc] initWithType:NRMAMT_Method]];
    }
    measurements = [producer drainMeasurements];
    XCTAssertTrue(numMeasurements == [[measurements objectForKey:[NSNumber numberWithInt:NRMAMT_Method]] count], @"");
    XCTAssertTrue(0 == [producer drainMeasurements].count, @"");
}

@end
