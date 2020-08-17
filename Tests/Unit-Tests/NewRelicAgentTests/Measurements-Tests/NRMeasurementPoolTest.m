//
//  NRMAMeasurementPoolTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/23/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMeasurementPoolTest.h"
#import "NRTestHelperConsumer.h"

@interface CountingMeasurementConsumer : NRMAMeasurementConsumer
{
    long consumedMeasurements;
}
- (long) consumedMeasurements;
- (void) resetCount;
@end
@implementation CountingMeasurementConsumer

- (void)resetCount {
    consumedMeasurements    = 0;
}
- (void) consumeMeasurement:(NRMAMeasurement *)measurement
{
    @synchronized(self) {
        consumedMeasurements++;
        [super consumeMeasurement:measurement];
    }
}

- (void) consumeMeasurements:(NSDictionary*)measurements
{
    @synchronized(self) {
        int size = 0;
        for (NSNumber* key in measurements) {
            size += [[measurements objectForKey:key] count];
        }
        [super consumeMeasurements:measurements];
    }
}

- (long) consumedMeasurements {
    return consumedMeasurements;
}

@end

@interface CountingMeasurementProducer : NRMAMeasurementProducer
{
    long producedMeasurementsCount;
}
- (long) producedMeasurementsCount;

@end

@implementation CountingMeasurementProducer
- (void) produceMeasurement:(NRMAMeasurement *)measurement {
    @synchronized(self) {
        [super produceMeasurement:measurement];
        producedMeasurementsCount++;
    }
}
- (long) producedMeasurementsCount {
    return producedMeasurementsCount;
}

@end

@interface RetainingConsumer : CountingMeasurementConsumer
@end

@implementation RetainingConsumer
- (void) consumeMeasurement:(NRMAMeasurement *)measurement
{
    consumedMeasurements++;
}

- (void) consumeMeasurements:(NSDictionary *)measurements {
    [super consumeMeasurements:measurements];
}
@end

@implementation NRMAMeasurementPoolTest

- (void) setUp
{
    [super setUp];
    pool = [[NRMAMeasurementPool alloc] init];
}

- (void) testAddMeasurementProducer
{
    NRMAMeasurementProducer* producer = [[NRMAMeasurementProducer alloc] initWithType:NRMAMT_NamedValue];
    [pool addMeasurementProducer:producer];

    XCTAssertTrue([[pool.producers objectForKey:[NSNumber numberWithInt:NRMAMT_NamedValue]] containsObject:producer],@"");

}
- (void) testRemoveMeasurementProducer
{
    NRMAMeasurementProducer* producer = [[NRMAMeasurementProducer alloc]initWithType:NRMAMT_NamedValue];
    [pool addMeasurementProducer:producer];

    XCTAssertTrue([[pool.producers objectForKey:[NSNumber numberWithInt:NRMAMT_NamedValue] ]
                  containsObject:producer], @"");
    [pool removeMeasurementProducer:producer];
    XCTAssertFalse([[pool.producers objectForKey:[NSNumber numberWithInt:NRMAMT_NamedValue]] containsObject:producer], @"");
}

- (void) testAddMeasurementConsumer
{
    NRMAMeasurementConsumer* consumer = [[NRMAMeasurementConsumer alloc] initWithType:NRMAMT_NamedEvent];
    [pool addMeasurementConsumer:consumer];
    XCTAssertTrue([[pool.consumers objectForKey:[NSNumber numberWithInt:NRMAMT_NamedEvent]] containsObject:consumer], @"");
    [pool addMeasurementConsumer:consumer];
    //add exception?
}

- (void) testRemoveMeasurementConsumer
{
    NRMAMeasurementConsumer *consumer = [[NRMAMeasurementConsumer alloc] initWithType:NRMAMT_HTTPError];
    [pool addMeasurementConsumer:consumer];

    XCTAssertTrue([[pool.consumers objectForKey:[NSNumber numberWithInt:NRMAMT_HTTPError]] containsObject:consumer], @"");
    [pool removeMeasurementConsumer:consumer];

    XCTAssertFalse([[pool.consumers objectForKey:[NSNumber numberWithInt:NRMAMT_HTTPError]] containsObject:consumer], @"");
}

static bool consumerfinished;
static bool producerfinished;
static const int totalMeasurements = 1000;
- (void) testConcurrencyProcessMeasurements
{
    consumerfinished = NO;
    producerfinished = NO;
    int numProducers = 1;
    for (int i=0; i < numProducers; i++) {
        [pool addMeasurementProducer:[[CountingMeasurementProducer alloc] initWithType:NRMAMT_HTTPError]];
    }

    int numConsumer = 5;
    for (int i = 0; i <numConsumer; i++) {
        [pool addMeasurementConsumer:[[CountingMeasurementConsumer alloc] initWithType:NRMAMT_HTTPError]];
    }
    [[[NSThread alloc] initWithTarget:self selector:@selector(concurrencyHelpConsumerThread) object:nil] start];
    [[[NSThread alloc] initWithTarget:self selector:@selector(concurrencyHelpProducerThread) object:nil]start];

    while (CFRunLoopGetCurrent() && (!consumerfinished || !producerfinished)){};

    long consumedMeasurements = 0;
    long producedMeasurements = 0;

    // for (NSNumber* key in pool.producers.allKeys) {
    for (CountingMeasurementProducer* producer in [pool.producers objectForKey:[NSNumber numberWithInt:NRMAMT_HTTPError]]) {
        producedMeasurements += [producer producedMeasurementsCount];
    }
    //}

    int consumerCount = 0;
    for(NSNumber* key in pool.consumers.allKeys) {
        for(CountingMeasurementConsumer* consumer in [pool.consumers objectForKey:key]) {
            consumedMeasurements += [consumer consumedMeasurements];
            consumerCount ++;
        }
    }


    XCTAssertTrue(consumedMeasurements == producedMeasurements*consumerCount, @"the number of measurements produced should equal the number consumed divided by consumers");

}


- (void) concurrencyHelpProducerThread {
    @autoreleasepool {


        int measurementCount = 0;
        while (CFRunLoopGetCurrent() && (measurementCount < totalMeasurements)) {
            int numMeasurments = arc4random()%1000;
            if (numMeasurments + measurementCount >= totalMeasurements) {
                numMeasurments = totalMeasurements - measurementCount;
            }

            for (NRMAMeasurementProducer* producer in [pool.producers objectForKey:[NSNumber numberWithInt:NRMAMT_HTTPError]]) {
                for (int i = 0; i < numMeasurments ; i ++) {
                    NRMAMeasurement *measurement = [[NRMAMeasurement alloc] initWithType:NRMAMT_HTTPError];
                    [producer produceMeasurement:measurement];
                }
                measurementCount += numMeasurments;
            }
            [NSThread sleepForTimeInterval:.2 + ((rand()%100 * 3)/100)];
        }
        producerfinished = YES;
    }
}
- (void) concurrencyHelpConsumerThread {
    @autoreleasepool {

        do {
            long producedMeasurementCount = 0;
            long consumedMeasurementCount = 0;

            //for (NSNumber* key in pool.producers.allKeys) {
            for(CountingMeasurementProducer* producer in [pool.producers objectForKey:[NSNumber numberWithInt:NRMAMT_HTTPError ]]) {
                producedMeasurementCount += [producer producedMeasurementsCount];
            }
            //}
            if (producedMeasurementCount >= totalMeasurements) {
                [pool broadcastMeasurements];
            }
            int consumerCount = 0;
            for (NSNumber* key in pool.consumers.allKeys) {
                for (NRMAMeasurementConsumer* consumer in [pool.consumers objectForKey:key]) {
                    consumerCount++;
                    consumedMeasurementCount += [((CountingMeasurementConsumer*)consumer) consumedMeasurements];
                }
            }
            if (consumedMeasurementCount >= totalMeasurements * consumerCount) {
                consumerfinished = YES;
                break;
            }

            [NSThread sleepForTimeInterval:.2 + ((rand()%100 * 3)/100)];

        } while (CFRunLoopGetCurrent() && !consumerfinished);

    }
}
- (void) testSimpleProcessMeasurements
{
    NRMATestHelperConsumer* consumer = [[NRMATestHelperConsumer alloc] initWithType:NRMAMT_HTTPError];
    NRMAMeasurementProducer* producer = [[NRMAMeasurementProducer alloc] initWithType:NRMAMT_Any];
    NRMAMeasurementProducer* producer2 = [[NRMAMeasurementProducer alloc] initWithType:NRMAMT_Method];

    [pool addMeasurementConsumer:consumer];
    [pool addMeasurementProducer:producer];
    [pool addMeasurementProducer:producer2];

    int numMeasurements = 1000;

    for (int i = 0; i < numMeasurements; i++){
        [producer produceMeasurement:[[NRMAMeasurement alloc] initWithType:NRMAMT_NamedValue]];
        [producer2 produceMeasurement:[[NRMAMeasurement alloc] initWithType:NRMAMT_Method]]; //we wont see these again
        [producer produceMeasurement:[[NRMAMeasurement alloc] initWithType:NRMAMT_HTTPError]];
    }

    XCTAssertTrue([[[producer producedMeasurements] objectForKey:[NSNumber numberWithInt:NRMAMT_HTTPError
                                                                 ]] count] == numMeasurements,@"");

    [pool broadcastMeasurements];

    XCTAssertTrue([[producer2 producedMeasurements]  count] == 0, @"producer should be empty");
    XCTAssertTrue([[producer producedMeasurements] count] == 0, @"producer should be empty");
    XCTAssertTrue([consumer.consumedmeasurements count] == 1, @"we should only be consuming one time");
    XCTAssertTrue([[consumer.consumedmeasurements objectForKey:[NSNumber numberWithInt:NRMAMT_HTTPError] ] count] == numMeasurements, @"we should have the expected type");

}

- (void) testConsumingProducesMeasurement
{
    NRMAMeasurement* measurement = [[NRMAMeasurement alloc] initWithType:NRMAMT_HTTPError];
    [pool consumeMeasurement:measurement];

    NSDictionary* producedmeasurements = [pool drainMeasurements];
    int count = 0;
    for (NSNumber* key in producedmeasurements.allKeys) {
        count += [[producedmeasurements objectForKey:key] count];
    }

    XCTAssertTrue(count == 1,@"");
    XCTAssertEqualObjects(measurement, ([(NSSet*)[producedmeasurements objectForKey:[NSNumber numberWithInt:NRMAMT_HTTPError]] anyObject]),@"there should only be one object and it should be the measurement");
}

- (void) testMeasurementPoolFillsFromAnotherPool {
    NRMAMeasurementProducer* producer = [[NRMAMeasurementProducer alloc] initWithType:NRMAMT_HTTPError];
    NRMAMeasurementPool* activePool = [[NRMAMeasurementPool alloc] init];
    [pool addMeasurementProducer:producer];
    [pool addMeasurementConsumer:activePool];
    for (int i = 0 ; i < 1000; i++) {
        [producer produceMeasurement:[[NRMAMeasurement alloc] initWithType:NRMAMT_HTTPError]];
    }

    [pool broadcastMeasurements];

    NSDictionary* dict = [activePool drainMeasurements];
    XCTAssertTrue([[dict objectForKey:[NSNumber numberWithInt:NRMAMT_HTTPError]]count] == 1000, @"activePool should get broadcasted measurements");
}
- (void) testEmptyBroadcast
{
    XCTAssertNoThrow([pool broadcastMeasurements], @"");
}

@end
