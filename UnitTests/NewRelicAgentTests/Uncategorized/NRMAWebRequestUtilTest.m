//
//  NRMAWebRequestUtilTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 7/21/16.
//  Copyright © 2016 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "NRMAWebRequestUtil.h"

@interface NRMAWebRequestUtilTest : XCTestCase

@end

@implementation NRMAWebRequestUtilTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/*
 + (BOOL) isWebViewRequest:(NSURLRequest*)request;
 + (NSMutableURLRequest*) setIsWebViewRequest:(NSURLRequest*)request;
 + (NSMutableURLRequest*) clearIsWebViewRequest:(NSURLRequest*)request;
 */

- (void) testWebRequestUtils
{
    NSURLRequest* aRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"blah"]];
    XCTAssertFalse([NRMAWebRequestUtil isWebViewRequest:aRequest]);

    aRequest = [NRMAWebRequestUtil setIsWebViewRequest:aRequest];
    XCTAssertTrue([NRMAWebRequestUtil isWebViewRequest:aRequest]);

    aRequest = [NRMAWebRequestUtil clearIsWebViewRequest:aRequest];
    XCTAssertFalse([NRMAWebRequestUtil isWebViewRequest:aRequest]);
}

@end
