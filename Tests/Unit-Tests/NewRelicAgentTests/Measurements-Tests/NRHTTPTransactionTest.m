//
//  NRMAHTTPTransactionTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/24/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAMeasurements.h"
#import "NRMeasurementConsumerHelper.h"
#import "NewRelicAgent+Development.h"
#import "NewRelicAgentInternal.h"
#import "NRTestConstants.h"
#import "NRMAHarvestController.h"
#import "NRMAHTTPTransactionMeasurement.h"
#import "NewRelicAgentTests.h"
#import "NRMANSURLConnectionSupport.h"
#import "NRAgentTestBase.h"
#import "NRMATaskQueue.h"
#import "NRMATraceController.h"
#import "NewRelicAgentInternal.h"
#import "NRTimer.h"
#import "NRMANetworkFacade.h"

#import <OCMock/OCMock.h>

#import "NRMAHTTPError.h"

@interface NRMATaskQueue ()
@property(strong) NSTimer *timer;
+ (NRMATaskQueue*) taskQueue;
@end

@interface NewRelicAgentInternal()
- (int)responseBodyCaptureSizeLimit;
@end

@interface NRMAHTTPTransactionTest : NRMAAgentTestBase
{
    NRMAMeasurementConsumerHelper* helper;
    id mockHarvestConnection;
    id mockAgentInstance;
}
@end

@implementation NRMAHTTPTransactionTest

- (void)setUp
{
    [super setUp];
    NRLOG_VERBOSE(@"setting up");
    [NRMANSURLConnectionSupport instrumentNSURLConnection];
    mockAgentInstance = [OCMockObject niceMockForClass:[NewRelicAgentInternal class]];
    mockHarvestConnection = [OCMockObject niceMockForClass:[NRMAHarvesterConnection class]];
    [[[[mockAgentInstance stub] classMethod] andReturn:mockAgentInstance] sharedInstance];
    [[[mockAgentInstance stub] andReturn:nil] analyticsController];
    [[[mockHarvestConnection stub] andReturn:@"blah"] crossProcessID];
    BOOL isactive=  YES;
    const char* type = "c";
    #ifdef __LP64__
    type = "B";
    #endif
    [[[mockAgentInstance stub] andReturnValue:[NSValue value:&isactive withObjCType:type]] enabled];

//    _NRMAAgentTestModeEnabled = YES;

//    [NewRelicAgentInternal startWithApplicationToken:kNRMA_ENABLED_STAGING_APP_TOKEN
//                         andCollectorAddress:KNRMA_TEST_COLLECTOR_HOST
//                                     withSSL:NO];
//    while (CFRunLoopGetMain() && [[NRMAHarvestController harvestController] harvester].currentState != NRMA_HARVEST_CONNECTED){};


    
//    double delayInSeconds = 5.0;
//    __block BOOL failed = NO;
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//    dispatch_after(popTime, dispatch_queue_create("timer_queue", NULL), ^(void){
//        failed = YES;
//    });

//    while (CFRunLoopGetMain() && ![NRMAHarvestController configuration]) {
//        //wait While harvester connects.
//        if (failed) {
//            STFail(@"Timeout reached for harvester to connect");
//            return;
//        
//        }
//    }

    [NRMATraceController startTracing:YES];
    [NRMAMeasurements initializeMeasurements];
    helper = [[NRMAMeasurementConsumerHelper alloc] initWithType:NRMAMT_HTTPTransaction];
    [NRMAMeasurements addMeasurementConsumer:helper];
    // Put setup code here; it will be run once, before the first test case.
}

- (void) tearDown
{
    NRLOG_VERBOSE(@"tearing down");
    [NRMANSURLConnectionSupport deinstrumentNSURLConnection];
    [NRMATraceController completeActivityTrace];
    [NRMAHarvestController stop];
    [NRMAMeasurements removeMeasurementConsumer:helper];
    [NRMAMeasurements shutdown];

    [mockHarvestConnection stopMocking];
    [mockAgentInstance stopMocking];
    [super tearDown];
}


- (void) testNSURLConnection
{
    NSURLRequest* request  = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com"]];
    
    
    NSURLResponse* response = nil;
    NSError* error = nil;
    [NSURLConnection sendSynchronousRequest:request
                          returningResponse:&response
                                      error:&error];
    
    __block BOOL failed = NO;
    double delayInSeconds = 10.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_queue_create("connectionTimeoutQueue", NULL), ^(void){
        failed = YES;
    });
    while (CFRunLoopGetCurrent() && helper.result == nil) {
        [NRMATaskQueue synchronousDequeue];
        if (failed) {
            XCTFail(@"Timeout reached for yahoo connection test");
            break;
        }
    }
    NSLog(@"%@",helper.result);
    
    XCTAssertTrue([helper.result isKindOfClass:[NRMAHTTPTransactionMeasurement class]], @"verify the result is a http transaction");
    XCTAssertTrue([((NRMAHTTPTransactionMeasurement*)helper.result).url isEqualToString:@"http://www.google.com"],@"match url to requested url");
}

//- (void) testASIConnection
//{
//    
//}

- (void) testNoticeHttpResponseCapturesBodyByDefault
{
    NRTimer *timer = [[NRTimer alloc] init];
    [timer stopTimer];
    __block BOOL finished = NO;
    NSString *responseBody = @"hoohahagoogle!";
    NSData *responseBodyData = [responseBody dataUsingEncoding:NSUTF8StringEncoding];
    id netFacadeMock = [OCMockObject niceMockForClass:[NRMANetworkFacade class]];
    id agentMock = [OCMockObject niceMockForClass:[NewRelicAgentInternal class]];
    [[[[netFacadeMock stub] classMethod] andReturnValue:@2048] responseBodyCaptureSizeLimit];
    [[[[agentMock stub] classMethod] andReturn:nil] sharedInstance];
    __block id mock = [OCMockObject mockForClass:[NRMAHTTPError class]];
    [[[mock stub] andReturn:mock] alloc];
    (void)[[[mock stub] andDo:^(NSInvocation *invocation) {
        [invocation setReturnValue:(__bridge void * _Nonnull)(mock)];
        finished = YES;
    }] initWithURL:OCMOCK_ANY
     httpMethod:OCMOCK_ANY
     timeOfError:timer.endTimeInMillis
     statusCode:404
     responseBody:responseBody
     parameters:OCMOCK_ANY
     wanType:OCMOCK_ANY
     appDataToken:nil
     threadInfo:OCMOCK_ANY];


    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com/"]];
    [request setHTTPMethod:@"GET"];
    NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                              statusCode:404
                                                             HTTPVersion:nil
                                                            headerFields:@{}];

    [NRMANetworkFacade noticeNetworkRequest:request
                                   response:response
                                  withTimer:timer
                                  bytesSent:0
                              bytesReceived:responseBodyData.length
                               responseData:responseBodyData
                                     params:@{}];

    while (CFRunLoopGetMain() && !finished) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    XCTAssertNoThrow([mock verify], @"noticeNetworkRequestForURLHttpUrl: should record a response body");
    [agentMock stopMocking];
    [netFacadeMock stopMocking];
    [mock stopMocking];
}

- (void) testNoticeHttpResponseObeysHttpResponseBodyCaptureConfig
{
    NRTimer *timer = [[NRTimer alloc] init];
    [timer stopTimer];
    
    NSString *responseBody = @"hoohahagoogle!";
    NSData *responseBodyData = [responseBody dataUsingEncoding:NSUTF8StringEncoding];
    
    id agentMock = [OCMockObject mockForClass:[NewRelicAgentInternal class]];
    id netFacadeMock = [OCMockObject niceMockForClass:[NRMANetworkFacade class]];
    [[[[netFacadeMock stub] classMethod] andReturnValue:@2048] responseBodyCaptureSizeLimit];

    [[[[agentMock stub] classMethod] andReturn:agentMock] sharedInstance];
    [[[agentMock stub] andReturn:nil] analyticsController];

    id mock = [OCMockObject mockForClass:[NRMAHTTPError class]];
    (void)[[[mock stub] andReturn:mock] initWithURL:OCMOCK_ANY
                                   httpMethod:OCMOCK_ANY
                                  timeOfError:timer.endTimeInMillis
                                   statusCode:404
                                 responseBody:@""
                                   parameters:OCMOCK_ANY
                                      wanType:OCMOCK_ANY
                                 appDataToken:nil
                                   threadInfo:OCMOCK_ANY];
    

    [NewRelic disableFeatures:NRFeatureFlag_HttpResponseBodyCapture];

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com/"]];
    [request setHTTPMethod:@"GET"];

    NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                              statusCode:404
                                                             HTTPVersion:nil
                                                            headerFields:@{}];
    [NRMANetworkFacade noticeNetworkRequest:request
                                   response:response
                                  withTimer:timer
                                  bytesSent:0
                              bytesReceived:responseBodyData.length
                               responseData:responseBodyData
                                     params:@{}];
    
    XCTAssertNoThrow([mock verify], @"noticeNetworkRequestForURLHttpUrl: should NOT record a response body");
    [agentMock stopMocking];
    [netFacadeMock stopMocking];
    [mock stopMocking];
}

@end
