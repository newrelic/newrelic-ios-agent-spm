//
//  NRMAThreadTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/29/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAThread.h"
#import "NRLogger.h"
#import "NRMATraceController.h"
#import <OCMock/OCMock.h>
@interface NRMAThreadTest : XCTestCase {
    BOOL executed;
}
@end

@implementation NRMAThreadTest

- (void)setUp
{
    [super setUp];
    [NRLogger setLogLevels:NRLogLevelNone];
    XCTAssertTrue([NRMAThread instrumentNSThread], @"assert NSThread instrumented");
}

- (void)tearDown
{
    BOOL success = [NRMAThread deinstrumentNSThread];
    XCTAssertTrue(success, @"assert NSThread deinstrumented");
    [super tearDown];
}


BOOL __threadExecuted;
- (void) testThread:(NSString*)string
{
    @autoreleasepool {
        __threadExecuted = YES;
    }
}

- (void) testExceptionHandler
{
    [NRMATraceController startTracing:YES];

    id mockTraceMachine = [OCMockObject niceMockForClass:[NRMATraceController class]];
    __threadExecuted = NO;
    executed = NO;
    [[[mockTraceMachine stub] andDo:^(NSInvocation *invocation) {
        executed = YES;
        @throw [NSException exceptionWithName:@"I's ded" reason:@"because" userInfo:nil];
    }] enterMethod:OCMOCK_ANY name:OCMOCK_ANY];

    [[mockTraceMachine expect] exitMethod];

    NSThread* myThread = [[NSThread alloc] initWithTarget:self selector:@selector(testThread:) object:@"hello world"];
    [myThread setThreadPriority:1];
    [myThread start];

    double delayInSeconds = 2.0;
    __block bool done = NO;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!done) {
        XCTAssertTrue(__threadExecuted, @"was -testThread: called?");
        XCTAssertTrue(executed, @"was the exception executed?");

        XCTFail(@"failed to complete wait loop after 2 seconds");
        }
    });

    while (CFRunLoopGetCurrent() && !executed && !__threadExecuted) {} //wait for thread to fire

    done = YES;

    XCTAssertThrows([mockTraceMachine verify], @"assert we didn't execute exitMethod");
    [mockTraceMachine stopMocking];
}

- (dispatch_queue_t) randomQueue
{
    int whichQueue = rand() % 2;
    switch(whichQueue) {
        case 0:
            return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        case 1:
            return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        default:
            XCTFail(@"shouldn't have fallen through randomQueue finder");
            return dispatch_get_main_queue();
    }
}
static int incrementer;
static NSString *incrementerLock;
- (void) sleepyThread: (NSNumber *) depth
{
    @autoreleasepool {
        [NRMATraceController startTracing:YES];

        long maxSleepyTime = 1000;
        int newDepth = [depth intValue] - 1;
        if (newDepth <= 0) {
            @synchronized(incrementerLock) {
                incrementer ++;
            }
            return;
        }

        dispatch_async([self randomQueue], ^{
            @autoreleasepool {
                [self sleepyThread:[NSNumber numberWithInt:newDepth]];
            }
        });
        usleep(rand() % maxSleepyTime);
        [NRMATraceController completeActivityTrace];

        @synchronized(incrementerLock) {
            incrementer ++;
        }
    }
}


@end
