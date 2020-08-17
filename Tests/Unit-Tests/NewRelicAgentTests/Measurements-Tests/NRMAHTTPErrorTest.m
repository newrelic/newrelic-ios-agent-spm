//
//  NRMAHTTPErrorTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 11/12/15.
//  Copyright © 2015 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NewRelic.h"
#import "NewRelicAgentInternal.h"
#import "NRMATaskQueue.h"
#import "NRMAHTTPError.h"
#import "NRMANetworkFacade.h"
#import <OCMock/OCMock.h>

@interface NRMAHTTPErrorTest : XCTestCase

@end

@implementation NRMAHTTPErrorTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void) testAppDataToken {

    NSURL* url = [NSURL URLWithString:@"www.google.com"];
    NRTimer* timer = [NRTimer new];
    NSString* appToken = @"NewRelic-Token";
    __block BOOL finished = NO;

    id mockQueue = [OCMockObject mockForClass:[NRMATaskQueue class]];
    [[[mockQueue stub] andDo:^(NSInvocation *invocation) {
        __autoreleasing NSObject* measurement;
        [invocation getArgument:&measurement atIndex:2];
        if ([measurement isKindOfClass:[NRMAHTTPError class]]) {
            XCTAssertEqualObjects(((NRMAHTTPError*)measurement).appData, appToken);
            finished = YES;
        }
    }] queue:OCMOCK_ANY];

    [NewRelic noticeNetworkRequestForURL:url
                              httpMethod:@"GET"
                               withTimer:timer
                         responseHeaders:@{NEW_RELIC_SERVER_METRICS_HEADER_KEY : appToken}
                              statusCode:404
                               bytesSent:100
                           bytesReceived:100
                            responseData:[@"hello, world" dataUsingEncoding:NSUTF8StringEncoding]
                               andParams:@{}];

    while (CFRunLoopGetCurrent() && !finished) {
         [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    [mockQueue stopMocking];
}

@end
