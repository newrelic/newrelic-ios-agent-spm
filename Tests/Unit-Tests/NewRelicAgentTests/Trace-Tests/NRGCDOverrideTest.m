



//
//  NRMAGCDOverrideTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/5/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRGCDOverrideTest.h"
#import "Public/NRGCDOverride.h"
#import "NRMATraceController.h"
#import "NRMAMeasurements.h"
#import "NRMAActivityTraceMeasurement.h"
#import "NRMAHarvestController.h"
#import "NRMATraceMachine.h"
#import "OCMock/OCMock.h"
#import "NRMATaskQueue.h"
@interface NRMATraceController ()
+ (void) setHealthyTraceTimeout:(NSUInteger) healthyTraceTimeout;
@end

@interface NRMATaskQueue ()
+ (NRMATaskQueue*) taskQueue;
+ (void) clear;
@end

@implementation NRMAGCDOverrideTest

- (void) setUp
{
    [super setUp];
    helper = [[NRMAMeasurementConsumerHelper alloc] initWithType:NRMAMT_Activity];
    [NRMAMeasurements initializeMeasurements];
    [NRMAMeasurements addMeasurementConsumer:helper];
    [NRMAHarvestController initialize:[[NRMAAgentConfiguration alloc] init]];
    [NRMATraceController startTracing:YES];
}

- (void) tearDown
{
    [super tearDown];
    [NRMAHarvestController stop];
    [NRMAMeasurements removeMeasurementConsumer:helper];
    [NRMAMeasurements shutdown];
    [NRMATaskQueue clear];
}
- (void) testDispatchAsync
{
    __block BOOL wait = YES;
    
    

    dispatch_queue_t queue = dispatch_queue_create("async_queue", NULL);
    dispatch_async(queue, ^{
        sleep(1);
        wait = NO;
    });
   
    while (CFRunLoopGetCurrent() && wait){};
    
    sleep(1); // we need to wait a moment for the trace machine to wrap up the last thread
    //if we don't there is a race condition with the completion resulting in a missing child!
    
    [NRMATraceController completeActivityTrace];

    [NRMATaskQueue synchronousDequeue];

    NRMATrace* parentTrace = ((NRMAActivityTraceMeasurement*)helper.result).rootTrace;
    NRMATrace* trace = parentTrace.children.anyObject;
    //we need to wait for this to populate?
    
 XCTAssertEqual(parentTrace.children.count, (NSUInteger)1, @"verify there is only one child in here");
    NSString*prefix = parentTrace.classLabel;
    if (![prefix length]) {
        prefix = parentTrace.name;
    }
    NSString* expectedName = [NSString stringWithFormat:@"dispatch_async"];
    XCTAssertTrue([trace.name isEqualToString:expectedName], @"got %@ expected %@",trace.name,expectedName);
}

- (void) testDispatchOnce
{
    __block BOOL wait = YES;
    
  
    __block int testNumber = 0;
    for (int i = 0 ; i < 10 ; i++ )
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sleep(1);
            wait = NO;
            testNumber++;
        });
    }
    
    XCTAssertEqual(testNumber, 1, @"test dispatch once only gets called once");
    
    while (CFRunLoopGetCurrent() && wait){};
    [NRMATraceController completeActivityTrace];

    [NRMATaskQueue synchronousDequeue];

    NRMATrace* parentTrace = ((NRMAActivityTraceMeasurement*)helper.result).rootTrace;
    NRMATrace* trace = parentTrace.children.anyObject;
    NSLog(@"%@",trace);
    NSString*prefix = parentTrace.classLabel;
     if (![prefix length]) {
        prefix = parentTrace.name;
     }
    NSString* expectedName =[NSString stringWithFormat:@"dispatch_once"];
    XCTAssertTrue([trace.name isEqualToString:expectedName], @"");
}

- (void) testDispatchAfter
{
    __block BOOL wait = YES;
    
    double delayInSeconds = 2.0;
    dispatch_queue_t dispatchQueue = dispatch_queue_create("newQueue", NULL);
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatchQueue, ^(void){
        wait = NO;
    });
    
    
    while (CFRunLoopGetCurrent() && wait) {
        NSLog(@"waiting");
        sleep(1);
    };
    
    [NRMATraceController completeActivityTrace];
    [NRMATaskQueue synchronousDequeue];
    NRMATrace* parentTrace = ((NRMAActivityTraceMeasurement*)helper.result).rootTrace;
    NRMATrace* trace = parentTrace.children.anyObject;
    NSLog(@"%@",trace);
    NSString*prefix = parentTrace.classLabel;
    if (![prefix length]) {
        prefix = parentTrace.name;
    }
    NSString* expectedName = [NSString stringWithFormat:@"dispatch_after"];
    XCTAssertTrue([trace.name isEqualToString:expectedName], @"%@ should be %@",trace.name, expectedName);
    
}

- (void) testDispatchSync
{
 //   __block BOOL wait = YES;
    dispatch_queue_t queue = dispatch_queue_create("testQueue", NULL);
    dispatch_sync(queue, ^{
            //pew pew
    });
    
    [NRMATraceController completeActivityTrace];
    [NRMATaskQueue synchronousDequeue];
    NRMATrace* parentTrace = ((NRMAActivityTraceMeasurement*)helper.result).rootTrace;
    NRMATrace* trace = ((NRMAActivityTraceMeasurement*)helper.result).rootTrace.children.anyObject;
    NSLog(@"%@",trace);
    NSString*prefix = parentTrace.classLabel;
    if (![prefix length]) {
        prefix = parentTrace.name;
    }
    NSString* expectedName = [NSString stringWithFormat:@"dispatch_sync"];
    XCTAssertTrue([trace.name isEqualToString:expectedName], @"");
}

- (void) testDispatchApply
{
    dispatch_queue_t queue = dispatch_queue_create("dispatchApply", NULL);
    dispatch_apply(10, queue,^(size_t index) {
        NSLog(@"%zu",index);
    });
    
    [NRMATraceController completeActivityTrace];
    [NRMATaskQueue synchronousDequeue];
    NRMATrace* parentTrace = ((NRMAActivityTraceMeasurement*)helper.result).rootTrace;
    NSString*prefix = parentTrace.classLabel;
    if (![prefix length]) {
        prefix = parentTrace.name;
    }
    NRMATrace* trace = ((NRMAActivityTraceMeasurement*)helper.result).rootTrace.children.anyObject;
    NSString* expectedName = [NSString stringWithFormat:@"dispatch_apply"];
    XCTAssertTrue([trace.name isEqualToString:expectedName], @"got %@ expected %@",trace.name,expectedName);
    XCTAssertEqual([((NRMAActivityTraceMeasurement*)helper.result).rootTrace.children count], (NSUInteger)10, @"make sure all sub-activities are recorded");
}

- (NRMAActivityTrace*) currentActivityTrace
{
    return [NRMATraceController currentTrace].traceMachine.activityTrace;
}

- (void) testDispatchAsyncStartingBeforeActivityTraceStarts
{
    [NRMATraceController completeActivityTrace];

    dispatch_queue_t queue = dispatch_queue_create("async_queue", NULL);
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    dispatch_async(queue, ^{
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    });

    // now, with an AT active, ensure that the block completes
    [NRMATraceController startTracing:NO];
    dispatch_semaphore_signal(sem);
    dispatch_sync(queue, ^{});
    NRMAActivityTrace* at = [self currentActivityTrace];
    [NRMATraceController completeActivityTrace];

    // one node for dispatch_sync call
    XCTAssertEqual(at.nodes, (NSUInteger)1, @"Expected 1 node in activity trace");

//    dispatch_release(queue);
//    dispatch_release(sem);
}

- (void) testDispatchAsyncEndingAfterActivityTraceEnds
{
    [NRMATraceController setHealthyTraceTimeout:10000]; //disable timeout
    [NRMATaskQueue synchronousDequeue];
    [NRMATraceController startTracing:YES];

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    // note that an AT is already running by virtue of the setUp method
    dispatch_async(queue, ^{ // i'm a node
        NSLog(@"I'm a good async");
    });

    dispatch_sync(queue, ^{
        NSLog(@"don't mind me... just sync'n"); 
    }); // i'm a node
    __block BOOL enteredAsync = NO;
    dispatch_async(queue, ^{ // i'm a node that is unhealth
        enteredAsync = YES;
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        NSLog(@"Blarg I'm finished");
    });

    while (CFRunLoopGetCurrent() && !enteredAsync) {}
    NRMAActivityTrace* at = [self currentActivityTrace];

    [NRMATraceController completeActivityTrace];
    [NRMATaskQueue synchronousDequeue];

    // let the async block finish after the AT is done
    dispatch_semaphore_signal(sem);
    dispatch_sync(queue, ^{}); //I'm not counted

    // one node for dispatch_async call
    XCTAssertEqual(at.nodes, (NSUInteger)3, @"Expected 3 node in activity trace");
    [NRMATraceController setHealthyTraceTimeout:.5]; //reset timeout
//    dispatch_release(queue);
//    dispatch_release(sem);
}

- (void) testDispatchAsyncEndingAfterNewActivityTraceIsStarted
{
    dispatch_queue_t queue = dispatch_queue_create("async_queue", NULL);
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    // note that an AT is already running by virtue of the setUp method
    __block BOOL wait1 = YES;
    __block BOOL wait2 = YES;
    dispatch_async(queue, ^{
        wait1 = NO;
        //get at least some exclusive time happening
    });
    dispatch_async(queue, ^{
        wait2 = NO;
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    });

    while (CFRunLoopGetCurrent() && (wait1 || wait2)) {} //wait for both asyncs to fire

    NRMAActivityTrace* at0 = [self currentActivityTrace];
    [NRMATraceController completeActivityTrace];

    XCTAssertEqual(at0.nodes, (NSUInteger)2, @"Expected 2 node in first activity trace");

    // start a new AT, and let the block complete during it
    [NRMATraceController startTracing:NO];
    NRMAActivityTrace* at1 = [self currentActivityTrace];
    dispatch_semaphore_signal(sem);
    dispatch_sync(queue, ^{});
    [NRMATraceController completeActivityTrace];

    // one node for the dispatch_sync call
    XCTAssertEqual(at1.nodes, (NSUInteger)1, @"Expected 1 node in second activity trace");

//    dispatch_release(queue);
//    dispatch_release(sem);
}

- (void) testDispatchAsyncStartingBeforeAndEndingAfterActivityTrace
{
    [NRMATraceController completeActivityTrace];

    dispatch_queue_t queue = dispatch_queue_create("async_queue", NULL);
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    dispatch_async(queue, ^{

    });
    dispatch_async(queue, ^{
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    });

    // start and finish a new AT
    [NRMATraceController startTracing:NO];
    NRMAActivityTrace* at = [self currentActivityTrace];
    [NRMATraceController completeActivityTrace];

    dispatch_semaphore_signal(sem);
    dispatch_sync(queue, ^{});

    XCTAssertEqual(at.nodes, (NSUInteger)0, @"Expected exactly 0 nodes");

//    dispatch_release(queue);
//    dispatch_release(sem);
}

- (void) testExceptionEnterDispatchMethod
{
    __block BOOL didThrow = NO;
    id traceMachineMock = [OCMockObject niceMockForClass:[NRMATraceController class]];
    [[[traceMachineMock stub] andDo:^(NSInvocation *invocation) {
        didThrow = YES;
        @throw [NSException exceptionWithName:@"asdf" reason:@"asdf" userInfo:nil];
    }] enterMethod:OCMOCK_ANY name:OCMOCK_ANY];

    __block BOOL didExecuteBlock = NO;
    dispatch_queue_t queue = dispatch_queue_create("create", NULL);
    XCTAssertNoThrow(dispatch_sync(queue, ^{
        didExecuteBlock = YES;
    }),@"assert did succeed execute dispatch_sync");

    XCTAssertTrue(didExecuteBlock, @"did execute block");
    XCTAssertTrue(didThrow, @"did throw exception");

    [traceMachineMock stopMocking];
}


- (void) testExceptionExitDispatchMethod
{
    __block BOOL didThrow = NO;
    id traceMachineMock = [OCMockObject niceMockForClass:[NRMATraceController class]];
    [[[traceMachineMock stub] andDo:^(NSInvocation *invocation) {
        didThrow = YES;
        @throw [NSException exceptionWithName:@"asdf" reason:@"asdf" userInfo:nil];
    }] exitMethod];

    __block BOOL didExecuteBlock = NO;
    dispatch_queue_t queue = dispatch_queue_create("create", NULL);
    XCTAssertNoThrow(dispatch_sync(queue, ^{
        didExecuteBlock = YES;
    }),@"assert did succeed execute dispatch_sync");

    XCTAssertTrue(didExecuteBlock, @"did execute block");
    XCTAssertTrue(didThrow, @"did throw exception");

    [traceMachineMock stopMocking];
}

@end
