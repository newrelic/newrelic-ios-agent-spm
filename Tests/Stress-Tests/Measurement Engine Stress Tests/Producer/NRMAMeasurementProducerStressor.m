//
//  NRMAMEasurementProducerStressor.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/11/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAStressTestHelper.h"
#import "NRMAMeasurementProducer.h"

@interface NRMAMeasurementProducerStressor : XCTestCase
 @property(strong,atomic)   NRMAMeasurementProducer* producer;
@property(atomic) unsigned long long asyncStartedCounter;
@property(atomic) unsigned long long asyncEndedCounter;
@property(strong) dispatch_semaphore_t semaphore;
@end

@implementation NRMAMeasurementProducerStressor

- (void)setUp
{
    [super setUp];
    NSUInteger procCount = [[NSProcessInfo processInfo] processorCount];
    self.semaphore = dispatch_semaphore_create(procCount*kNRMASemaphoreMultiplier);
    self.producer = [[NRMAMeasurementProducer alloc] initWithType:NRMAMT_Any];
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

- (void)tearDown
{
    self.producer = nil;
    [super tearDown];
}



- (void) testStress
{

    XCTAssertNoThrow([self stress], @"failed stress test");
}

- (void) stress
{
    @autoreleasepool {
        int iteractions = kNRMAIterations;
        for (int i = 0; i < iteractions; i++) {
            [self incrementAsyncCounter];
            //These semaphores prevent the dispatch_async calls from blowing out the stack
            //they would otherwise get queued faster than they could be execute
            //thus creating a huge growth in heap size.
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
            dispatch_async([NRMAStressTestHelper randomDispatchQueue], ^{
                @autoreleasepool {
                    [self executeRandomly];
                    [self incrementAsyncEndedCounter];
                    dispatch_semaphore_signal(self.semaphore);
                }
            });
            [self incrementAsyncCounter];
            //These semaphores prevent the dispatch_async calls from blowing out the stack
            //they would otherwise get queued faster than they could be execute
            //thus creating a huge growth in heap size.
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
            dispatch_async([NRMAStressTestHelper randomDispatchQueue], ^{

                @autoreleasepool {
                    self.producer = nil;
                    self.producer = [[NRMAMeasurementProducer alloc] initWithType:NRMAMT_Any];
                    [self incrementAsyncEndedCounter];
                    dispatch_semaphore_signal(self.semaphore);
                }
            });
        }
    }
    while (CFRunLoopGetCurrent() && self.asyncEndedCounter < self.asyncStartedCounter) {}
}

- (void) executeRandomly
{
    int options = 3;
    @autoreleasepool {
        switch (rand() % options) {
            case 0:
                [self.producer produceMeasurement:[[NRMAMeasurement alloc] initWithType:NRMAMT_HTTPError]];
                break;
            case 1:
                [self.producer produceMeasurements:@{[NSNumber numberWithInt:NRMAMT_HTTPError]:
                                                         [[NSMutableSet alloc] initWithObjects:[[NRMAMeasurement alloc] initWithType:NRMAMT_HTTPError],nil]}];
                break;
            case 2:
                [self.producer drainMeasurements];
                break;
            default:
                break;
        }
    }
}
@end
