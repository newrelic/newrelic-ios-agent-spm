//
//  NewRelicAPITests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 11/4/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NRMeasurementConsumerHelper.h"
#import "NRMAHarvestController.h"
#import "NRMAActivityTraceMeasurement.h"
#import "NRMATraceController.h"
#import "NRMAMeasurements.h"
#import "NRMAMethodSwizzling.h"
#import <OCMock/OCMock.h>
#import <objc/runtime.h>
#import "NRMATaskQueue.h"
#import "NewRelic.h"
#import "NewRelicAgentInternal.h"
#import "NRMAAnalytics.h"
#import <OCMock/OCMock.h>




BOOL NRMA__shouldCancelCurrentTrace(id __unsafe_unretained obj);

@interface NRMATaskQueue ()
+ (NRMATaskQueue*) taskQueue;
+ (void) clear;
@end

@interface NRMAAnalytics ()
- (NSString*) sessionAttributeJSONString;
@end

@interface NewRelicAPITests : XCTestCase
{
    NRMAMeasurementConsumerHelper* helper;
}
@end

@implementation NewRelicAPITests

- (void)setUp
{
    [super setUp];
    [NRMATaskQueue clear];
    helper = [[NRMAMeasurementConsumerHelper alloc] initWithType:NRMAMT_Activity];
    [NRMAMeasurements initializeMeasurements];
    [NRMAMeasurements addMeasurementConsumer:helper];
    [NRMAHarvestController configuration].at_capture.maxTotalTraceCount = 1000;

}

- (void)tearDown
{
    [NRMAMeasurements removeMeasurementConsumer:helper];
    [NRMAMeasurements shutdown];
    [super tearDown];
}

- (void) testLastInteraction
{
    id mockAgentInternal = [OCMockObject niceMockForClass:[NewRelicAgentInternal class]];

    NRMAAnalytics* analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:0];

    [[[[mockAgentInternal stub] classMethod]  andReturn:mockAgentInternal] sharedInstance];

    [[[mockAgentInternal stub] andReturn:analytics] analyticsController];

    NSString* kDefaultName = @"Hello World";
    NR_START_NAMED_INTERACTION(kDefaultName);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sleep(1);
    });
    [NRMATraceController completeActivityTrace];

    [NRMATaskQueue synchronousDequeue];
    XCTAssertNotNil(helper.result, @"a trace should be created");
    XCTAssertTrue([helper.result isKindOfClass:[NRMAActivityTraceMeasurement class]], @"it should be an Activity measurement");

    NSString* traceName = ((NRMAActivityTraceMeasurement*)helper.result).traceName;
    NSString* expectedName = kDefaultName;
    XCTAssertEqualObjects(traceName,expectedName, @"");
//    STAssertEqualObjects(traceName,[NSString stringWithFormat:@"%@#%@",NSStringFromClass([self class]),NSStringFromSelector(_cmd)], @"macro should work properly");

    NSString* json = [analytics sessionAttributeJSONString];

    NSDictionary* decode = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding]
                                                           options:0
                                                             error:nil];

    XCTAssertNotNil(decode[@"lastInteraction"]);
    XCTAssertTrue([decode[@"lastInteraction"] isEqualToString:@"Hello World"]);

    NR_START_NAMED_INTERACTION(@"BlahBlahBlah");

    json = [analytics sessionAttributeJSONString];

    decode = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding]
                                             options:0
                                               error:nil];

    XCTAssertNotNil(decode[@"lastInteraction"]);
    XCTAssertTrue([decode[@"lastInteraction"] isEqualToString:@"BlahBlahBlah"]);


    [mockAgentInternal stopMocking];
}
- (void) testInteractionTrace
{

    NSString* kDefaultName = @"Hello World";
    NR_START_NAMED_INTERACTION(kDefaultName);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sleep(1);
    });
    [NRMATraceController completeActivityTrace];

    [NRMATaskQueue synchronousDequeue];
    XCTAssertNotNil(helper.result, @"a trace should be created");
    XCTAssertTrue([helper.result isKindOfClass:[NRMAActivityTraceMeasurement class]], @"it should be an Activity measurement");
    
    NSString* traceName = ((NRMAActivityTraceMeasurement*)helper.result).traceName;
    NSString* expectedName = kDefaultName;
    XCTAssertEqualObjects(traceName,expectedName, @"");
//    STAssertEqualObjects(traceName,[NSString stringWithFormat:@"%@#%@",NSStringFromClass([self class]),NSStringFromSelector(_cmd)], @"macro should work properly");
}


- (void) testStartTracingMethod
{
    NR_TRACE_METHOD_START(NRTraceTypeNone);
    sleep(1);
    NR_TRACE_METHOD_STOP;

    XCTAssertNil(__nr__trace__timer, @"this should be cleaned up");
}


- (void) testExceptionHandlerStartTracingMethod
{
    id mockTraceMachine = [OCMockObject niceMockForClass:[NRMATraceController class]];
    [[[mockTraceMachine stub] andDo:^(NSInvocation *invocation) {
        @throw [NSException exceptionWithName:@"I's ded" reason:@"because" userInfo:nil];
    }] registerNewTrace:OCMOCK_ANY
     withParent:OCMOCK_ANY];

    [NRMATraceController startTracing:YES];
    XCTAssertTrue([NRMATraceController isTracingActive], @"assert we are running a trace maching");
    NRTimer* timer = [NRTimer new];
    [[mockTraceMachine expect] exitCustomMethodWithTimer:timer];

    XCTAssertNoThrow([NRMACustomTrace startTracingMethod:_cmd
                                              objectName:NSStringFromClass(self.class)
                                                   timer:timer
                                                category:NRTraceTypeDatabase],@"the exception handler should catch the exception");

    //assert clean up worked
    XCTAssertNil(objc_getAssociatedObject(timer, (__bridge const void *)kNRTraceAssociatedKey), @"the timer associated trace isn't set");
    XCTAssertFalse([NRMATraceController isTracingActive], @"The trace maching was disable");

    [NRMACustomTrace endTracingMethodWithTimer:timer];

    XCTAssertThrows([mockTraceMachine verify], @"we never reached this code due to the earlier exception, therefore it shan't be called");


    [mockTraceMachine stopMocking];
}

- (void) testExceptionHandlerEndTracingMethodWithTimer
{
    id mockTraceMachine = [OCMockObject niceMockForClass:[NRMATraceController class]];
    [[[mockTraceMachine stub] andDo:^(NSInvocation *invocation) {
        @throw [NSException exceptionWithName:@"I's ded" reason:@"because" userInfo:nil];
    }] exitCustomMethodWithTimer:OCMOCK_ANY];

    [NRMATraceController startTracing:YES];

    XCTAssertTrue([NRMATraceController isTracingActive], @"assert we are running a trace maching");

    NRTimer* timer = [NRTimer new];

    [NRMACustomTrace startTracingMethod:_cmd
                             objectName:NSStringFromClass(self.class)
                                  timer:timer
                               category:NRTraceTypeNone];

    XCTAssertNotNil(objc_getAssociatedObject(timer, (__bridge const void *)kNRTraceAssociatedKey), @"the timer associated trace isn't set");

    XCTAssertNoThrow([NRMACustomTrace endTracingMethodWithTimer:timer], @"shouldn't be effected by the exception");

    XCTAssertFalse([NRMATraceController isTracingActive], @"trace machine terminated");

    [mockTraceMachine stopMocking];

}




static int dispatchB;
static int dispatchC;
- (dispatch_queue_t) randomQueue
{
    int whichQueue = rand() % 2u;
    switch(whichQueue) {
//        case 0:
//            dispatchA++;
//            dispatch_queue_t queueA = dispatch_get_main_queue();
//            return queueA;
        case 0:
            dispatchB++;
            return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        case 1:
            dispatchC++;
            return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        case 3:
//            dispatchD++;
//            dispatch_queue_t queueD =dispatch_get_current_queue();
//            return queueD;
        default:
            XCTFail(@"shouldn't have fallen through randomQueue finder");
            return dispatch_get_main_queue();
    }
}
static long long finished;
//- (void) testCompleteActivityTraceRace
//{
//    dispatchA=0;
//    dispatchB=0;
//    dispatchC=0;
//    dispatchD= 0;
//    int numberOfRuns = 5100;
//    int dispatched = 0;
//    int chanceOfStartCall = 50;
//    int chanceofCompletedCall = 10;
//    finished = 0;
//    __block long long started = 0;
//
//    if ([NRMATraceController isTracingActive]) {
//        [NRMATraceController completeActivityTrace];
//    }
//    sleep(1);
// [self overridecCompleteActivityTrace];
//
//    for(int t = 0; t < numberOfRuns; t++) {
//        if (rand() % 2 == 0) {
//            for (int i = 0; i < rand() % chanceOfStartCall; i++) {
//                dispatched ++;
//                dispatch_async([self randomQueue], ^{
//                    [NRMATraceController startTracing:YES];
//                    started++;
//                });
//            }
//        } else {
//            for (int i = 0; i < rand() % chanceofCompletedCall; i++) {
//                dispatch_async([self randomQueue], ^{
//                    [NRMATraceController completeActivityTrace];
//                });
//            }
//        }
//    }
//
//
//    while (CFRunLoopGetMain() && (dispatched > finished || dispatched > started)){
//    }; //wait for everything to finished
//    [self resetCompleteActivityTraceOverride];
//
//    sleep(1);
//}

BOOL NRMA__traceMachine_completeActivityTrace(id self, SEL _cmd);
static IMP NRMATraceMachine_completeActivityTrace_Orig;
- (void) overridecCompleteActivityTrace
{
  NRMATraceMachine_completeActivityTrace_Orig = NRMAReplaceClassMethod([NRMATraceController class], @selector(completeActivityTrace),(IMP)NRMA__traceMachine_completeActivityTrace);
}
- (void) resetCompleteActivityTraceOverride
{
    NRMATraceMachine_completeActivityTrace_Orig = NRMAReplaceClassMethod([NRMATraceController class], @selector(completeActivityTrace), NRMATraceMachine_completeActivityTrace_Orig);
    NRMATraceMachine_completeActivityTrace_Orig = NULL;
}
- (void) testStopCurrentInteractionTrace
{
    NSString* guid = NR_START_NAMED_INTERACTION(@"hello world");
    XCTAssertTrue([NRMATraceController isTracingActive], @"interaction trace should be active!");
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sleep(1);
    });
    NR_INTERACTION_STOP(guid);
    XCTAssertFalse([NRMATraceController isTracingActive], @"interaction trace should be inactive");
    [NRMATaskQueue synchronousDequeue];
    XCTAssertNotNil(helper.result, @"a trace should be created");
    XCTAssertTrue([helper.result isKindOfClass:[NRMAActivityTraceMeasurement class]], @"it should be an Activity measurement");

}

- (void) testFailedToStopInteractionTrace
{
    NR_START_NAMED_INTERACTION(@"hello world");
    XCTAssertTrue([NRMATraceController isTracingActive], @"interaction trace should be active!");
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sleep(1);
    });
    NR_INTERACTION_STOP(nil);
    XCTAssertTrue([NRMATraceController isTracingActive], @"interaction trace shouldn't have stopped because we didn't pass the guid.");

    [NRMATraceController completeActivityTrace];
}

@end

BOOL NRMA__traceMachine_completeActivityTrace(id self, SEL _cmd)
{
 BOOL success =  ((BOOL(*)(__strong id,SEL))NRMATraceMachine_completeActivityTrace_Orig)(self, _cmd);
    if (success){
        finished ++;
    }
    return success;
}

