//
//  NRMAConnectionTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/8/17.
//  Copyright © 2017 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAConnection.h"
#import "NewRelicAgentInternal.h"
#import "NewRelicInternalUtils.h"
#import "NRAgentTestBase.h"
@interface NRMAConnectionTest : NRMAAgentTestBase

@end

@implementation NRMAConnectionTest


- (void)testConnection {
    NRMAConnection* connection = [[NRMAConnection alloc] init];
    connection.applicationToken = @"token";
    connection.useSSL = YES;
    connection.applicationVersion = [NRMAAgentConfiguration connectionInformation].applicationInformation.appVersion;
    NSURLRequest* request = [connection newPostWithURI:@"google.com"];

    XCTAssertTrue([request.allHTTPHeaderFields[NEW_RELIC_OS_NAME_HEADER_KEY] isEqualToString:[NewRelicInternalUtils osName]]);
    XCTAssertTrue([request.allHTTPHeaderFields[NEW_RELIC_APP_VERSION_HEADER_KEY] isEqualToString:@"1.0"]);
    XCTAssertTrue([request.allHTTPHeaderFields[X_APP_LICENSE_KEY_REQUEST_HEADER] isEqualToString:@"token"]);

}

@end
