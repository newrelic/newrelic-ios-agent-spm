//
//  NRMARequestEvents.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/18/17.
//  Copyright © 2017 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAAnalytics+cppInterface.h"
#import "NRMAFlags.h"
@interface NRMARequestEvents : XCTestCase

@end

@interface NRMANetworkRequestData ()
- (NewRelic::NetworkRequestData*) getNetworkRequestData;
@end

static NRMAFeatureFlags __originalFlags;
@implementation NRMARequestEvents

- (void)setUp {
    [super setUp];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __originalFlags = [NRMAFlags featureFlags];
    });
    [NRMAFlags setFeatureFlags:0];

    [NRMAAnalytics clearDuplicationStores];
}

- (void)tearDown {
    [NRMAFlags setFeatureFlags:__originalFlags];
    [super tearDown];
}

- (void) testDisableFeatureFlag {

    NRTimer* timer = [NRTimer new];
    [NRMAFlags disableFeatures:NRFeatureFlag_RequestErrorEvents];
    NRMAAnalytics* analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:0];
    
    NSURL* url = [[NSURL alloc] initWithString:@"https://rpm.newrelic.com"];
    NRMANetworkRequestData* requestData = [[NRMANetworkRequestData alloc] initWithRequestUrl:url
                                                                                  httpMethod:@"GET"
                                                                              connectionType:@"wifi"
                                                                                 contentType:nil
                                                                                   bytesSent:1];
    
    NRMANetworkResponseData* responseData = [[NRMANetworkResponseData alloc] initWithHttpError:400
                                                                                 bytesReceived:2
                                                                                  responseTime:[timer timeElapsedInSeconds]
                                                                           networkErrorMessage:@""
                                                                           encodedResponseBody:nil
                                                                                 appDataHeader:nil];

    BOOL result = [analytics addNetworkRequestEvent:requestData withResponse:responseData withPayload:nullptr];
    
    XCTAssertFalse(result);
}

- (void) testCorrectURLCapture {

    NSURL* url = [[NSURL alloc] initWithString:@"https://rpm.newrelic.com/asdf/as%20df.jsx"];
    NRMANetworkRequestData* requestData = [[NRMANetworkRequestData alloc] initWithRequestUrl:url
                                                                                  httpMethod:@"GET"
                                                                              connectionType:@"wifi"
                                                                                 contentType:nil
                                                                                   bytesSent:1];

    auto result = [requestData getNetworkRequestData];

    NSString* requestDomain = [NSString stringWithFormat:@"%s",result->getRequestDomain()];
    NSString* requestPath = [NSString stringWithFormat:@"%s", result->getRequestPath()];
    NSString* absoluteUrl = [NSString stringWithFormat:@"%s", result->getRequestUrl()];

    XCTAssertTrue([requestDomain isEqualToString:@"rpm.newrelic.com"]);
    XCTAssertTrue([requestPath isEqualToString:@"/asdf/as df.jsx"]);
    XCTAssertTrue([absoluteUrl isEqualToString:@"https://rpm.newrelic.com/asdf/as df.jsx"]);
}

- (void) testCorrectPoorlyFormedURLCapture {

    NSURL* url = [[NSURL alloc] initWithString:@"rpm.newrelic.com"];
    NRMANetworkRequestData* requestData = [[NRMANetworkRequestData alloc] initWithRequestUrl:url
                                                                                  httpMethod:@"GET"
                                                                              connectionType:@"wifi"
                                                                                 contentType:nil
                                                                                   bytesSent:1];

    auto result = [requestData getNetworkRequestData];

    NSString* requestDomain = [NSString stringWithUTF8String:result->getRequestDomain()?:""];
    NSString* requestPath = [NSString stringWithUTF8String:result->getRequestPath()?:""];
    NSString* absoluteUrl = [NSString stringWithUTF8String:result->getRequestUrl()?:""];

    XCTAssertTrue([requestDomain isEqualToString:@""]);
    XCTAssertTrue([requestPath isEqualToString:@"rpm.newrelic.com"]); //be aware: the NSURLRequest API will return this
                                                                      //value as the requestPath for some reason when
                                                                      //no scheme (protocol) is applied
    XCTAssertTrue([absoluteUrl isEqualToString:@"rpm.newrelic.com"]);
}


- (void) testBasicURLCapture {

    NSURL* url = [[NSURL alloc] initWithString:@"http://rpm.newrelic.com"];
    NRMANetworkRequestData* requestData = [[NRMANetworkRequestData alloc] initWithRequestUrl:url
                                                                                  httpMethod:@"GET"
                                                                              connectionType:@"wifi"
                                                                                 contentType:nil
                                                                                   bytesSent:1];

    auto result = [requestData getNetworkRequestData];

    NSString* requestDomain = [NSString stringWithUTF8String:result->getRequestDomain()?:""];
    NSString* requestPath = [NSString stringWithUTF8String:result->getRequestPath()?:""];
    NSString* absoluteUrl = [NSString stringWithUTF8String:result->getRequestUrl()?:""];

    XCTAssertTrue([requestDomain isEqualToString:@"rpm.newrelic.com"]);
    XCTAssertTrue([requestPath isEqualToString:@""]);
    XCTAssertTrue([absoluteUrl isEqualToString:@"http://rpm.newrelic.com"]);
}


@end
