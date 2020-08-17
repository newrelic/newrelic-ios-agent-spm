//
//  NRMAActivityTraceMeasurementCreatorStressor.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/11/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAActivityTraceMeasurementCreator.h"
#import "NRMAStressTestHelper.h"
#import "NRMAActivityTraceMeasurement.h"
@interface NRMAActivityTraceMeasurementCreatorStressor : XCTestCase
@property(strong, atomic) NRMAActivityTraceMeasurementCreator* consumer;
@property(atomic) unsigned long long asyncStartedCounter;
@property(atomic) unsigned long long asyncEndedCounter;
@property(strong) dispatch_semaphore_t semaphore;
@end

@implementation NRMAActivityTraceMeasurementCreatorStressor

- (void)setUp
{
    [super setUp];
    NSUInteger procCount = [[NSProcessInfo processInfo] processorCount];
    self.semaphore = dispatch_semaphore_create(procCount*kNRMASemaphoreMultiplier);
    self.consumer = [[NRMAActivityTraceMeasurementCreator alloc] init];;
}

- (void)tearDown
{
    self.consumer = nil;
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
    int iterator = kNRMAIterations;
    for (int i = 0; i < iterator; i++) {
        @autoreleasepool {
            [self incrementAsyncCounter];
            //These semaphores prevent the dispatch_async calls from blowing out the stack
            //they would otherwise get queued faster than they could be execute
            //thus creating a huge growth in heap size.
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
            dispatch_async([NRMAStressTestHelper randomDispatchQueue],^(){
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
            dispatch_async([NRMAStressTestHelper randomDispatchQueue],^(){
                @autoreleasepool {
                    self.consumer = nil;
                    self.consumer = [[NRMAActivityTraceMeasurementCreator alloc] init];;
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
    @autoreleasepool {
        int options = 2;
        NRMAActivityTraceMeasurement* measurement = [[NRMAActivityTraceMeasurement alloc] initWithActivityTrace:[[NRMAActivityTrace alloc] initWithRootTrace:[[NRMATrace alloc] initWithName:@"blah" traceMachine:nil]]];
        switch (rand() % options) {
            case 0:
                [self.consumer consumeMeasurement:measurement];
                break;
            case 1:
                [self.consumer consumeMeasurements:@{[NSNumber numberWithInt:NRMAMT_HTTPError]
                                                     :[[NSMutableSet alloc] initWithObjects:measurement,nil]}];
                break;
            default:
                break;
        }
    }
}
@end
