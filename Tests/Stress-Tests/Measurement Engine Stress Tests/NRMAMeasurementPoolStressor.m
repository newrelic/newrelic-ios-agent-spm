//
//  NRMAMeasurementPoolStressor.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/12/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAMeasurementPool.h"
#import "NRMAStressTestHelper.h"
@interface NRMAMeasurementPoolStressor : XCTestCase
@property(strong) id<NRMAProducerProtocol> producer;
@property(strong) id<NRMAConsumerProtocol> consumer;
@property(strong) NRMAMeasurementPool* testPool;
@property(atomic) unsigned long long asyncStartedCounter;
@property(atomic) unsigned long long asyncEndedCounter;

@property(strong) dispatch_semaphore_t semaphore;
@end

@implementation NRMAMeasurementPoolStressor

- (void)setUp
{
    [super setUp];
    self.producer = [[NRMAMeasurementProducer alloc] initWithType:NRMAMT_Any];
    self.consumer = [[NRMAMeasurementConsumer alloc] initWithType:NRMAMT_Any];
    self.testPool = [[NRMAMeasurementPool alloc] init];
    NSUInteger procCount = [[NSProcessInfo processInfo] processorCount];
    self.semaphore = dispatch_semaphore_create(procCount*kNRMASemaphoreMultiplier);
}

- (void)tearDown
{
    self.producer = nil;
    self.consumer = nil;
    [self.testPool shutdown];
    self.semaphore = nil;
    self.testPool = nil;
    [super tearDown];
}
- (void) incrementAsyncCounter
{
    static NSString* lock = @"mylock";
    @synchronized(lock) {
        self.asyncStartedCounter++;
    }
}
- (void)incrementAsyncEndedCounter
{
    static NSString* lock = @"myLock2";
    @synchronized(lock) {
        self.asyncEndedCounter++;
    }
}

- (void) testStress
{
    XCTAssertNoThrow([self stress], @"failed stress test");
}

- (void) stress
{
    int iterations =  kNRMAIterations;
    for (int i = 0; i < iterations; i++) {
        @autoreleasepool {
            [self incrementAsyncCounter];

            //These semaphores prevent the dispatch_async calls from blowing out the stack
            //they would otherwise get queued faster than they could be execute
            //thus creating a huge growth in heap size.
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
            dispatch_async([NRMAStressTestHelper randomDispatchQueue], ^{
                @autoreleasepool {
                    [self.producer produceMeasurement:[[NRMAMeasurement alloc] initWithType:NRMAMT_Activity]];
                    [self.producer produceMeasurement:[[NRMAMeasurement alloc] initWithType:NRMAMT_Activity]];
                    [self.producer produceMeasurement:[[NRMAMeasurement alloc] initWithType:NRMAMT_Activity]];
                    [self incrementAsyncEndedCounter];
                    //signal semaphore we are done!
                    dispatch_semaphore_signal(self.semaphore);
                }
            });
            [self incrementAsyncCounter];
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
            dispatch_async([NRMAStressTestHelper randomDispatchQueue], ^{
                @autoreleasepool {
                    [self.producer produceMeasurement:[[NRMAMeasurement alloc] initWithType:NRMAMT_HTTPError]];
                    [self.producer produceMeasurement:[[NRMAMeasurement alloc] initWithType:NRMAMT_Method]];
                    [self.producer produceMeasurement:[[NRMAMeasurement alloc] initWithType:NRMAMT_NamedEvent]];
                    [self incrementAsyncEndedCounter];
                    dispatch_semaphore_signal(self.semaphore);
                }
            });
            [self incrementAsyncCounter];
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
            dispatch_async([NRMAStressTestHelper randomDispatchQueue], ^{
                @autoreleasepool {
                    [self executeRandomly];
                    [self incrementAsyncEndedCounter];
                    dispatch_semaphore_signal(self.semaphore);
                }
            });
        }
    }

//this allows us to makes sure all processing is done in this test before we move on to the next one!
    while (CFRunLoopGetCurrent() && self.asyncEndedCounter < self.asyncStartedCounter) {}

}

- (void) executeRandomly
{
    @autoreleasepool {
        int options = 5;
        switch (rand() % options) {
            case 0:
                [self.testPool addMeasurementConsumer:self.consumer];
                break;
            case 1:
                [self.testPool addMeasurementProducer:self.producer];
                break;
            case 2:
                [self.testPool removeMeasurementConsumer:self.consumer];
                break;
            case 3:
                [self.testPool removeMeasurementProducer:self.producer];
                break;
            case 4:
                [self.testPool broadcastMeasurements];
                break;
            case 5:
                [self.testPool shutdown];
                self.testPool = nil;
                self.testPool = [[NRMAMeasurementPool alloc] init];
            default:
                break;
        }
    }
}

@end
