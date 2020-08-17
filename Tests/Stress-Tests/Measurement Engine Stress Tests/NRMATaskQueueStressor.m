//
//  NRMATaskQueueStressor.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/12/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMATaskQueue.h"
#import "NRMAStressTestHelper.h"
#import "NRMATrace.h"
#import "NRMAActivityTrace.h"
#import "NRMAMetric.h"
#import "NRMATraceController.h"
#import "NewRelic.h"
#import "NRMAInteractionHistoryObjCInterface.h"
@interface NRMATaskQueueStressor : XCTestCase
@property(atomic) unsigned long long asyncStartedCounter;
@property(atomic) unsigned long long asyncEndedCounter;
@property(strong) dispatch_semaphore_t semaphore;
@end

@implementation NRMATaskQueueStressor

- (void)setUp
{
    [super setUp];
    NSUInteger procCount = [[NSProcessInfo processInfo] processorCount];
    self.semaphore = dispatch_semaphore_create(procCount*kNRMASemaphoreMultiplier);
}

- (void)tearDown
{
    [super tearDown];
}

- (void) testStartAndStop
{
    // the task queue can start and stop asynchronously
    // depending on the app backgrounding and foregrounding
    XCTAssertNoThrow([self stressStartAndStop], @"Failed stress test!");
}

- (void) stressStartAndStop
{
    int iterations = kNRMAIterations;
    
    for (int i = 0; i<iterations; i++) {
        @autoreleasepool {
            if(i  % 1000 == 0) {
                NSLog(@"iteration: %d", i);
            }
            NSString* endme = NR_START_NAMED_INTERACTION(@"dispatch");
            [self incrementAsyncCounter];
            //These semaphores prevent the dispatch_async calls from blowing out the stack
            //they would otherwise get queued faster than they could be execute
            //thus creating a huge growth in heap size.
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
            dispatch_async([NRMAStressTestHelper randomDispatchQueue], ^{
                @autoreleasepool {
                    [NRMATaskQueue start];
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
                    [NRMATaskQueue stop];
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
                [self executeTaskQueueRandomly];
                [self incrementAsyncEndedCounter];
                dispatch_semaphore_signal(self.semaphore);
            });
            [self incrementAsyncCounter];
            //These semaphores prevent the dispatch_async calls from blowing out the stack
            //they would otherwise get queued faster than they could be execute
            //thus creating a huge growth in heap size.
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
            dispatch_async([NRMAStressTestHelper randomDispatchQueue], ^{
                [self executeHTTPStuffRandomly];
                [self incrementAsyncEndedCounter];
                dispatch_semaphore_signal(self.semaphore);
            });
            
            NR_INTERACTION_STOP(endme);
        [NRMAInteractionHistoryObjCInterface deallocInteractionHistory];//interaction history starts adding up if we don't clear it out.
        }
    }

    while (CFRunLoopGetCurrent() && self.asyncEndedCounter < self.asyncStartedCounter) {}
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

- (void) executeTaskQueueRandomly
{
    int option = 4;
    switch (rand() % option) {
        case 0:
            [NRMATaskQueue start];
            [NRMATaskQueue synchronousDequeue];
            break;
        case 1:
            [NRMATaskQueue start];
            [NRMATaskQueue queue:[[NRMATrace alloc] init]];
            break;
        case 2:
            [NRMATaskQueue start];
            [NRMATaskQueue queue:[[NRMAActivityTrace alloc] initWithRootTrace:[[NRMATrace alloc] init]]];
            break;
        case 3:
            [NRMATaskQueue stop];
            break;
        default:
            break;
    }
}

- (void) executeHTTPStuffRandomly
{
    NRTimer* timer = [[NRTimer alloc] init];
    int option = 3;
    switch (rand() % option) {
        case 0:
            [timer stopTimer];
            [NewRelic noticeNetworkFailureForURL:[NSURL URLWithString:@"http://google.com"]
                                      httpMethod:@"GET"
                                       withTimer:timer
                                  andFailureCode:-1000];
            break;
        case 1:
            [timer stopTimer];
            [NewRelic noticeNetworkRequestForURL:[NSURL URLWithString:@"http://yahoo.com"]
                                      httpMethod:@"GET"
                                       withTimer:timer
                                 responseHeaders:nil
                                      statusCode:200
                                       bytesSent:200
                                   bytesReceived:200
                                    responseData:nil
                                       andParams:nil];
            break;
        case 2:
            [timer stopTimer];
            [NewRelic noticeNetworkRequestForURL:[NSURL URLWithString:@"http://yahoo.com"]
                                      httpMethod:@"GET"
                                       withTimer:timer
                                 responseHeaders:nil
                                      statusCode:500
                                       bytesSent:200
                                   bytesReceived:200
                                    responseData:nil
                                       andParams:nil];
            break;
        default:
            break;
    }
}

@end

