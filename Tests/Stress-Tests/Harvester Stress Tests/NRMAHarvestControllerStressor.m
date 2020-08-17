//
//  NRMAHarvestControllerStressor.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/19/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAStressTestHelper.h"
#import "NRMAHarvestController.h"
#import "NRMAMethodProfiler.h"
#import <objc/runtime.h>
#import "OCMock/OCMock.h"
#import "NRAgentTestBase.h"
#import "NRMAAppToken.h"
@interface NRMAHarvestControllerStressor : NRMAAgentTestBase <NRMAHarvestAware>
{
    NRMAAgentConfiguration* config;
    NRMAHarvestableActivity* activity;
    NRMAHarvestableHTTPError* httpError;
    NRMAHarvestableHTTPTransaction* trans;
}
@property(atomic) unsigned long long asyncStartedCounter;
@property(strong) dispatch_semaphore_t semaphore;
@property(atomic) unsigned long long asyncEndedCounter;
@end

@implementation NRMAHarvestControllerStressor

- (void)setUp
{
    [super setUp];
    NSUInteger procCount = [[NSProcessInfo processInfo] processorCount];
    self.semaphore = dispatch_semaphore_create(procCount*kNRMASemaphoreMultiplier);
    config = [[NRMAAgentConfiguration alloc] initWithAppToken:[[NRMAAppToken alloc] initWithApplicationToken:@"AAd75d4d5a3045711bd5ae829d0f043b1fbf893152"] collectorAddress:@"staging-mobile-collector.newrelic.com" crashAddress:nil];
    
    activity = [[NRMAHarvestableActivity alloc] init];
    activity.childSegments = [[NSMutableArray alloc] init];
    activity.sendAttempts = 0;
    activity.lastActivityStamp = @[@[@"MEH!",@1234567890]];


    [NRMAHarvestController initialize:config];
    [NRMAHarvestController start];
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
    [NRMAHarvestController stop];
    config = nil;
    [super tearDown];
}

- (void) testStress
{
    XCTAssertNoThrow([self stress], @"failed stress test");
}


- (void) stress
{
    @autoreleasepool {
        int iterations = kNRMAIterations;
        for (int i = 0; i < iterations; i++) {
            @autoreleasepool {
                [self incrementAsyncCounter];
                //These semaphores prevent the dispatch_async calls from blowing out the stack
                //they would otherwise get queued faster than they could be execute
                //thus creating a huge growth in heap size.
                dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
                dispatch_async([NRMAStressTestHelper randomDispatchQueue], ^{
                    @autoreleasepool {
                        [self randomlyExecute];
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
                        [self randomlyRestart];
                        [self incrementAsyncEndedCounter];
                    dispatch_semaphore_signal(self.semaphore);
                    }
                });
                
                if (i % 1000 == 0) {
                    while (CFRunLoopGetCurrent() && self.asyncEndedCounter < self.asyncStartedCounter) {}
                }
            }
        }
        while (CFRunLoopGetCurrent() && self.asyncEndedCounter < self.asyncStartedCounter) {}
    }
}


- (void) randomlyExecute
{
    int options = 5;

    switch (rand() % options) {
        case 0:
            [NRMAHarvestController harvestData];
            break;
        case 1:
            [NRMAHarvestController recovery];
            break;
        case 2:
            [NRMAHarvestController addHarvestListener:self];
            break;
        case 3:
            [NRMAHarvestController harvestNow];
            break;
        case 4:
            [NRMAHarvestController addHarvestableActivity:activity];
            break;

        default:
            break;
    }

}

static NSString* harvestControllerLock = @"";
- (void) randomlyRestart
{
    switch (rand() % 5) {
        case 0:
            @synchronized(harvestControllerLock) {
                [NRMAHarvestController stop];
                [NRMAHarvestController initialize:config];
                [NRMAHarvestController start];
            }
            break;
        default:
            break;
    }
}

- (void) onHarvestStart
{

}

- (void) onHarvestBefore
{

}

- (void) onHarvestComplete
{

}

@end
