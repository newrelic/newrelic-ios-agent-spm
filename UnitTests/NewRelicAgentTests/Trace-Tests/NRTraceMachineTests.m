//
//  NRMATraceMachineTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/12/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRTraceMachineTests.h"
#import "NRMATraceController.h"
#import "NRMATraceMachine.h"
#import "NRMAThread.h"
#import <OCMock/OCMock.h>
#import "NRMAActivityTraceMeasurement.h"
#import "NRMAMeasurements.h"
#import "NRMAHarvestableTrace.h"
#import "NRMAHarvestableActivity.h"
#import "NRMACustomTrace.h"
#import "NRMAHarvestController.h"
#import <pthread.h>
#import "NRMAMethodProfiler.h"
#import "NRMATaskQueue.h"
#import "NRMAThreadLocalStore.h"
#import "NewRelic.h"
#import "NRGCDOverride.h"

@interface NRMATaskQueue ()
+ (NRMATaskQueue*) taskQueue;
@end

@interface NRMATraceController (asdf)
+ (void) setUnhealthyTraceTimeout:(NSUInteger)millseconds;
+ (void) setHealthyTraceTimeout:(NSUInteger) healthyTraceTimeout;
+ (void) completeTrace:(NRMATrace*)trace withExitTimestampMillis:(NSNumber*)exitTimestampMilliseconds;
@end

@interface NRMAThreadLocalStore (TMTests)
+ (NSMutableDictionary*)threadDictionaries;
+ (NSMutableDictionary *)currentThreadDictionary;
@end


@implementation NRMATraceMachineTests

- (void) setUp
{
    [NRLogger setLogLevels:NRLogLevelNone];
    helper = [[NRMAMeasurementConsumerHelper alloc] initWithType:NRMAMT_Activity];
    [NRMAMeasurements initializeMeasurements];
    [NRMAMeasurements addMeasurementConsumer:helper];
    [NRMATraceController startTracing:YES];
    [NRMAThread instrumentNSThread];
    trueValue = YES;
    falseValue = NO;
    harvestConfigurationObject = [OCMockObject niceMockForClass:[NRMAHarvestController class]];
    NRMAHarvesterConfiguration* config = [[NRMAHarvesterConfiguration alloc] init];
    config.at_capture = nil;
    config.collect_network_errors = YES;
    config.data_report_period= 60;
    config.error_limit = 3;
    config.report_max_transaction_age = 5;
    config.report_max_transaction_count = 2000;
    config.response_body_limit = 1024;
    config.stack_trace_limit = 2000;
    config.activity_trace_max_send_attempts = 2;
    config.activity_trace_min_utilization = 0; //need to set this to 0 so we can capture all the stuff.
    [NRMAHarvestController configuration].at_capture = [[NRMATraceConfigurations alloc] init];
    [NRMAHarvestController configuration].at_capture.maxTotalTraceCount = 1000;

    [[[harvestConfigurationObject stub] andReturn:config] configuration];


//    [[[[harvestConfigurationObject stub] classMethod] andReturnValue:[NSValue value:&trueValue withObjCType:@encode(BOOL)]] shouldCollectTraces];
//    [[[[harvestConfigurationObject stub] classMethod] andReturnValue:[NSValue value:&falseValue withObjCType:@encode(BOOL)]] shouldNotCollectTraces];

}

- (void) tearDown
{
    [NRMAMeasurements removeMeasurementConsumer:helper];
    helper = nil;
    [NRMAMeasurements shutdown];
    [harvestConfigurationObject stopMocking];

}


- (void) testThreadCapture
{
   //wait for trace to complete
    __block bool done = NO;
    dispatch_queue_t queue = dispatch_queue_create("blah", NULL);
//    [NRMATraceController startTracing:YES];
    [NRMATraceController startTracing:YES];

    [NSThread detachNewThreadSelector:@selector(thread1) toTarget:self withObject:nil];
    NR_TRACE_METHOD_START(NRTraceTypeNone);

    dispatch_async(queue, ^{ //we need to not block on the main thread or else nothing will happen.

        [self function];

        done = YES;

    });

    NR_TRACE_METHOD_STOP
    while (CFRunLoopGetCurrent() && !done) {
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }; //wait for tracing to finish

}

- (void) function {
    while (CFRunLoopGetCurrent() && helper.result == nil) {
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
    }; //wait for tracing to finish

    XCTAssertNotNil(helper.result, @"a trace should be created");
    XCTAssertTrue([helper.result isKindOfClass:[NRMAActivityTraceMeasurement class]], @"it should be an Activity measurement");

//    NRMATrace* trace = [((NRMAActivityTraceMeasurement*)helper.result).rootTrace.children.allObjects objectAtIndex:0];

    for (NRMATrace* trace in ((NRMAActivityTraceMeasurement*)helper.result).rootTrace.children.allObjects) {
        XCTAssertTrue([trace.name isEqualToString:@"NRMATraceMachineTests#thread1"] || [trace.name isEqualToString:@"dispatch_async"] || [trace.name isEqualToString:@"NRMATraceMachineTests#testThreadCapture"], @"failed test with %@",trace.name);
    }

//    XCTAssertEqualObjects(trace.name,@"NRMATraceMachineTests#thread1", @"should have a name of the class and selector.");
    NRMAActivityTraceMeasurement* measurement = (NRMAActivityTraceMeasurement*)helper.result;
    NRMAHarvestableActivity* harvestableActivity = [[NRMAHarvestableActivity alloc] init];
    harvestableActivity.name = measurement.traceName;
    harvestableActivity.startTime = measurement.startTime;
    harvestableActivity.endTime = measurement.endTime;
    [harvestableActivity.childSegments addObject:[[NRMAHarvestableTrace alloc] initWithTrace:measurement.rootTrace]];

    (void)[harvestableActivity JSONObject];
}

- (void) thread1
{

    NR_TRACE_METHOD_START(NRTraceTypeNone);
    @autoreleasepool {
        //look busy
        sleep(1);
        for (int i = 1; i < 10000;i++)
        {
            int w = 1;
            w += i;
        }
    }
    NR_TRACE_METHOD_STOP;
}

- (void) testCustomActivity
{
    [NRMATraceController startTracing:YES];
    helper.result = nil;
    [NewRelic startInteractionWithName:@"Test"];
    __block BOOL wait = YES;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //nop
        sleep(1);
        wait = NO;
    });
    while (CFRunLoopGetCurrent() && wait) {}
    [NRMATraceController completeActivityTrace];
    [NRMATaskQueue synchronousDequeue];
    NSLog(@"%@",helper);
    XCTAssertEqualObjects(((NRMAActivityTraceMeasurement*)helper.result).traceName, @"Test", @"");
}


- (void) testUnhealthyTrace
{
    [NRMATraceController completeActivityTrace];
    helper.result = nil;

    [NRMATraceController startTracing:YES];
    [NRMATraceController enterMethod:@selector(unhealthy)
                     fromObjectNamed:NSStringFromClass(self.class)
                         parentTrace:[NRMATraceController currentTrace]
                       traceCategory:NRTraceTypeNone];

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sleep(1);
    });
    [NRMATraceController completeActivityTrace];

    [NRMATaskQueue synchronousDequeue];
    NSLog(@"%@",helper.result);

    XCTAssertTrue(helper.result, @"assert we got a result");


    NSSet* children = ((NRMAActivityTraceMeasurement*)helper.result).rootTrace.children;
    NRMATrace* unhealthyTrace = (NRMATrace*)[children anyObject];

    XCTAssertTrue([children count]  == 1, @"assert we have a child");
    NSString* name = [[children anyObject] name];
    NSString* expected = [NSString stringWithFormat:@"%@#unhealthy",NSStringFromClass(self.class)];
    XCTAssertEqualObjects(name, expected , @"assert we have the correct item");


    XCTAssertTrue(unhealthyTrace.exitTimestamp == 0, @"no endtime, because we didn'tOCMock finish");
}


- (void) testNodeLimit
{
    [NRMATraceController startTracing:YES];
    for (int i = 0; i < 2010; i++) {
        [NRMATraceController enterMethod:@selector(test)
                         fromObjectNamed:NSStringFromClass(self.class)
                             parentTrace:[NRMATraceController currentTrace]
                           traceCategory:NRTraceTypeNone];
//        NSLog(@"Logging to add cycles");
        [NRMATraceController exitMethod];
    }

    [NRMATraceController completeActivityTrace];

    [NRMATaskQueue synchronousDequeue];

    NSUInteger nodeCount = [((NRMAActivityTraceMeasurement*)helper.result).rootTrace.children count];
    XCTAssertEqual(nodeCount, (NSUInteger)2000, @"node count should be limited to 2000");
}

- (void) testAssignThreadDictionary
{
}

- (void) testTransTraceGCDCalls
{
    [NRMATraceController completeActivityTrace];
    helper.result = nil;

    [NRMATraceController startTracing:YES];
    NRTimer* timer = [NRTimer new];
    [NewRelic startTracingMethod:_cmd object:self timer:timer category:NRTraceTypeImages];
    dispatch_queue_t myqueue = dispatch_queue_create("pwd", NULL);
    __block BOOL finished = NO;
    dispatch_async(myqueue, ^{
        sleep(6);
        finished = YES;
    });
    __block BOOL finished2 = NO;
    dispatch_async(myqueue, ^{
        while (CFRunLoopGetCurrent() && !finished) {};
        finished2 = YES;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [[NRMAThreadLocalStore currentThreadDictionary] removeAllObjects];
        });
    });
    sleep(1);
    [NewRelic endTracingMethodWithTimer:timer];
    [NRMATraceController completeActivityTrace];

    [NRMATraceController startTracing:YES];

    while (CFRunLoopGetCurrent() && !finished2) {};
    sleep(4);
    [NRMATraceController completeActivityTrace];
}

- (void)testPopCurrentCalled
{
    id exitTraceMock = [OCMockObject niceMockForClass:[NRMAThreadLocalStore class]];
    [[exitTraceMock expect] popCurrentTraceIfEqualTo:OCMOCK_ANY returningParent:[OCMArg anyObjectRef]];//we don't want this called
    __block BOOL done = NO;

    XCTAssertTrue([NRMATraceController isTracingActive], @"tracing should be active at this time");

    dispatch_queue_t queue = dispatch_queue_create("meeh", NULL);
    dispatch_async(queue, ^{
        done = YES;
    });

    while (CFRunLoopGetCurrent() && !done) {}
    sleep(1); // give the dispatch async to actually run "completion" code

    [NRMATraceController completeActivityTrace];
    [NRMATaskQueue synchronousDequeue];
    XCTAssertNoThrow([exitTraceMock verify], @"This should have been called");

    [exitTraceMock stopMocking];

}
- (void) testTraceConsistency
{
    //traces started in an old activity shouldn't be picked up by a new one.
    id exitTraceMock = [OCMockObject niceMockForClass:[NRMAThreadLocalStore class]];
    [[exitTraceMock expect] popCurrentTraceIfEqualTo:OCMOCK_ANY returningParent:[OCMArg anyObjectRef]];//we don't want this called
    __block BOOL started = NO;
    __block BOOL wait = YES;
    __block NSString* pid = nil;

    NRMAActivityTrace* old_at = [NRMATraceController currentTrace].traceMachine.activityTrace;
    XCTAssertTrue([NRMATraceController isTracingActive], @"tracing should be active at this time");

    dispatch_queue_t queue = dispatch_queue_create("meeh", NULL);
    dispatch_async(queue, ^{
        started = YES;
        pid = [NSString stringWithFormat:@"%d",pthread_mach_thread_np(pthread_self())];
        while (CFRunLoopGetCurrent() && wait) { }
    });

    while (CFRunLoopGetCurrent() && !started) {}
    [NRMATraceController completeActivityTrace];
    [NRMATaskQueue synchronousDequeue];

    XCTAssertFalse([NRMATraceController isTracingActive], @"tracing should NOT be active at this time");

    [NRMATraceController startTracing:YES];
    NRMAActivityTrace* at = [NRMATraceController currentTrace].traceMachine.activityTrace;

    XCTAssertFalse(at == old_at, @"traces should not be equal");

    wait = NO;
    sleep(1); // give the dispatch async to actually run "completion" code

    [NRMATraceController completeActivityTrace];
    [NRMATaskQueue synchronousDequeue];

    XCTAssertTrue(at.nodes == 0, @"we shouldn't pick-up the old async started in old trace");
    XCTAssertTrue([((NSDictionary*)[[NRMAThreadLocalStore threadDictionaries] objectForKey:pid]) count] == 0, @"the thread dictionary for the failed thread should be cleansed");
    XCTAssertThrows([exitTraceMock verify], @"This should not have been called");


    [exitTraceMock stopMocking];

}

- (void) testNRMAThreadTraceNoCrash
{
    XCTAssertNoThrow([NRMATraceController completeTrace:nil withExitTimestampMillis:[NSNumber numberWithDouble:123]], @"");

    NRMATrace* trace = [[NRMATrace alloc] initWithName:@"Mrow" traceMachine:nil];
    XCTAssertNoThrow([NRMATraceController completeTrace:trace withExitTimestampMillis:[NSNumber numberWithDouble:123123]], @"");
}

- (void) TestThreadLocalTraceCrash
{
    [NRMATraceController completeActivityTrace]; //in case there is an activity trace running

    [NRMATraceController enterMethod:_cmd
                     fromObjectNamed:NSStringFromClass(self.class)
                         parentTrace:nil
                       traceCategory:NRTraceTypeNone];
    {
        [NRMATraceController startTracing:YES];

        [NRMATraceController enterMethod:@selector(innerMethod)
                         fromObjectNamed:NSStringFromClass(self.class)
                             parentTrace:nil
                           traceCategory:NRTraceTypeNone];
        
        [NRMATraceController exitMethod]; //ok
    }
    
    XCTAssertNoThrow([NRMATraceController exitMethod],@"this shouldn't crash"); //crash
    
    [NRMATraceController completeActivityTrace];
}

@end
