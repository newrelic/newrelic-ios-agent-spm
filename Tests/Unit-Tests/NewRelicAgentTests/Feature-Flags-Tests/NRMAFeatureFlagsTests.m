//
//  NRMAFeatureFlagsTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/28/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAFLags.h"



static NRMAFeatureFlags __originalFlags;
@interface NRMAFeatureFlagsTests : XCTestCase
@end

@implementation NRMAFeatureFlagsTests

- (void)setUp
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __originalFlags = [NRMAFlags featureFlags];
    });
    [NRMAFlags setFeatureFlags:0];

    [super setUp];
}

- (void)tearDown
{
    [NRMAFlags setFeatureFlags:__originalFlags];
    [super tearDown];
}



- (void) testOriginalFlags
{
    NRMAFeatureFlags featureFlag = __originalFlags;
    XCTAssertTrue(featureFlag & NRFeatureFlag_CrashReporting, @"crash reporting should be enabled by default!!");
    XCTAssertFalse(featureFlag & NRFeatureFlag_NetworkRequestEvents, @"Network requests events should be disabled by default!!");
    XCTAssertTrue(featureFlag & NRFeatureFlag_RequestErrorEvents, @"request error events should be enabled by default!!");
}



- (void) testNetworkRequestEventsFlags {
    NRMAFeatureFlags flags = [NRMAFlags featureFlags];
    XCTAssertFalse(flags, @"flags should be empty");

    [NRMAFlags enableFeatures:NRFeatureFlag_NetworkRequestEvents];
    flags = [NRMAFlags featureFlags];

    XCTAssertTrue(flags & NRFeatureFlag_NetworkRequestEvents, @"NetworkNRequestEvents should be enabled.");
    XCTAssertFalse(flags & ~NRFeatureFlag_NetworkRequestEvents, @"no other bits should be enabled.");

    [NRMAFlags disableFeatures:NRFeatureFlag_NetworkRequestEvents];
    flags = [NRMAFlags featureFlags];
    XCTAssertFalse(flags & NRFeatureFlag_NetworkRequestEvents, @"NetworkNRequestEvents should be disabled.");
    XCTAssertFalse(flags, @"flags should be empty");
}

- (void) testRequestErrorEventsFlags {
    NRMAFeatureFlags flags = [NRMAFlags featureFlags];
    XCTAssertFalse(flags, @"flags should be empty");

    [NRMAFlags enableFeatures:NRFeatureFlag_RequestErrorEvents];
    flags = [NRMAFlags featureFlags];

    XCTAssertTrue(flags & NRFeatureFlag_RequestErrorEvents, @"NetworkNRequestEvents should be enabled.");
    XCTAssertFalse(flags & ~NRFeatureFlag_RequestErrorEvents, @"no other bits should be enabled.");

    [NRMAFlags disableFeatures:NRFeatureFlag_RequestErrorEvents];
    flags = [NRMAFlags featureFlags];
    XCTAssertFalse(flags & NRFeatureFlag_RequestErrorEvents, @"NetworkNRequestEvents should be disabled.");
    XCTAssertFalse(flags, @"flags should be empty");
}

- (void)testFlagsEnable
{
    NRMAFeatureFlags flags = [NRMAFlags featureFlags];
    XCTAssertFalse(flags, @"flags should be empty");

    [NRMAFlags  enableFeatures:NRFeatureFlag_NSURLSessionInstrumentation];
    flags = [NRMAFlags featureFlags];

    XCTAssertTrue(flags & NRFeatureFlag_NSURLSessionInstrumentation, @"flags should have NSURLSession instrumentation enabled");

    XCTAssertFalse(flags & ~NRFeatureFlag_NSURLSessionInstrumentation , @"flags shouldn't have any other bit enabled.");
    
    [NRMAFlags  enableFeatures:NRFeatureFlag_ExperimentalNetworkingInstrumentation];
    
    flags = [NRMAFlags featureFlags];
    XCTAssertTrue(flags & NRFeatureFlag_ExperimentalNetworkingInstrumentation, @"flags should have experimental network instrumentation enabled");
    XCTAssertTrue(flags & NRFeatureFlag_NSURLSessionInstrumentation, @"flags should have NSURLSession instrumentation enabled");

}


- (void) testFlagDisable
{
    NRMAFeatureFlags flags = [NRMAFlags featureFlags];
    XCTAssertFalse(flags, @"flags should be empty");

    [NRMAFlags enableFeatures:(NRMAFeatureFlags)~0ULL];
    flags = [NRMAFlags featureFlags];

    XCTAssertTrue(flags == (~0ULL), @"feature flags should equal all features");
    XCTAssertTrue(flags & NRFeatureFlag_ExperimentalNetworkingInstrumentation, @"flags should have experimental network instrumentation enabled");
    XCTAssertTrue(flags & NRFeatureFlag_NSURLSessionInstrumentation, @"flags should have NSURLSession instrumentation enabled");

    [NRMAFlags disableFeatures:NRFeatureFlag_NSURLSessionInstrumentation];

    flags = [NRMAFlags featureFlags];

    XCTAssertFalse(flags & NRFeatureFlag_NSURLSessionInstrumentation, @"NSURLSessionInstrumentation should be disabled");

    XCTAssertTrue(flags == (NRFeatureFlag_NSURLSessionInstrumentation ^ ~0ULL), @"only NewRelicNSURLSessionInstrumentation should be disabled");
    
    [NRMAFlags disableFeatures:NRFeatureFlag_ExperimentalNetworkingInstrumentation];
    XCTAssertFalse(flags & NRFeatureFlag_NSURLSessionInstrumentation, @"Experimental networking instrumentation should be disabled");
}

- (void) testWebViewFlags
{
    XCTAssertFalse([NRMAFlags shouldEnableWebViewInstrumentation],@"");

    [NRMAFlags enableFeatures:NRFeatureFlag_WebViewInstrumentation];

    XCTAssertTrue([NRMAFlags shouldEnableWebViewInstrumentation],@"");

    [NRMAFlags disableFeatures:NRFeatureFlag_WebViewInstrumentation];

    XCTAssertFalse([NRMAFlags shouldEnableWebViewInstrumentation],@"");

    XCTAssertTrue([NRMAFlags featureFlags] == 0, @"feature flags should be back at 0");

}

- (void) testShouldEnableNSURLSessionInstrumentation
{
    XCTAssertFalse([NRMAFlags shouldEnableNSURLSessionInstrumentation], @"since no flags have been set this should be false!");

    [NRMAFlags enableFeatures:NRFeatureFlag_NSURLSessionInstrumentation];

    XCTAssertTrue([NRMAFlags shouldEnableNSURLSessionInstrumentation], @"this should now be enabled");

    [NRMAFlags disableFeatures:NRFeatureFlag_NSURLSessionInstrumentation];

    XCTAssertFalse([NRMAFlags shouldEnableNSURLSessionInstrumentation], @"this again be false!");

    XCTAssertTrue([NRMAFlags featureFlags] == 0, @"feature flags should be back at 0");
}

- (void) testShouldEnableExperimentalNetworkingInstrumentation
{
    XCTAssertFalse([NRMAFlags shouldEnableExperimentalNetworkingInstrumentation], @"since no flags have been set this should be false!");
    
    [NRMAFlags enableFeatures:NRFeatureFlag_ExperimentalNetworkingInstrumentation];
    
    XCTAssertTrue([NRMAFlags shouldEnableExperimentalNetworkingInstrumentation], @"this should now be enabled");
    
    [NRMAFlags disableFeatures:NRFeatureFlag_ExperimentalNetworkingInstrumentation];
    
    XCTAssertFalse([NRMAFlags shouldEnableExperimentalNetworkingInstrumentation], @"this again be false!");
    
    XCTAssertTrue([NRMAFlags featureFlags] == 0, @"feature flags should be back at 0");

}

- (void) testShouldEnableHttpResponseBodyCapture
{
    XCTAssertFalse([NRMAFlags shouldEnableHttpResponseBodyCapture], @"since no flags have been set this should be false!");
    
    [NRMAFlags enableFeatures:NRFeatureFlag_HttpResponseBodyCapture];
    
    XCTAssertTrue([NRMAFlags shouldEnableHttpResponseBodyCapture], @"this should now be enabled");
    
    [NRMAFlags disableFeatures:NRFeatureFlag_HttpResponseBodyCapture];
    
    XCTAssertFalse([NRMAFlags shouldEnableHttpResponseBodyCapture], @"this again be false!");
    
    XCTAssertTrue([NRMAFlags featureFlags] == 0, @"feature flags should be back at 0");
}

- (void) testShouldEnableDistributedTracing
{
    XCTAssertFalse([NRMAFlags shouldEnableDistributedTracing], @"since no flags have been set this should be false!");
    
    [NRMAFlags enableFeatures:NRFeatureFlag_DistributedTracing];
    
    XCTAssertTrue([NRMAFlags shouldEnableDistributedTracing], @"this should now be enabled");
    
    [NRMAFlags disableFeatures:NRFeatureFlag_DistributedTracing];
    
    XCTAssertFalse([NRMAFlags shouldEnableDistributedTracing], @"this again be false!");
    
    XCTAssertTrue([NRMAFlags featureFlags] == 0, @"feature flags should be back at 0");
}

@end
