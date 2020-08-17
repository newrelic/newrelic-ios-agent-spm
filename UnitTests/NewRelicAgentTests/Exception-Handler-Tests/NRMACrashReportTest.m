//
//  NRMACrashReportTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 6/14/16.
//  Copyright © 2016 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NewRelicInternalUtils.h"
#import "NRMACrashReport.h"

@interface NRMACrashReportTest : XCTestCase

@end

@implementation NRMACrashReportTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testOSName {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    NRMACrashReport* report = [[NRMACrashReport alloc] initWithUUID:@"asdf"
                                                    buildIdentifier:@"blah"
                                                          timestamp:@1
                                                           appToken:@"token"
                                                          accountId:@213
                                                            agentId:@1123
                                                         deviceInfo:nil
                                                            appInfo:nil
                                                          exception:nil
                                                            threads:nil
                                                          libraries:nil
                                                    activityHistory:nil
                                                  sessionAttributes:nil
                                                    AnalyticsEvents:nil];

#if TARGET_OS_TV
    XCTAssertTrue([[report JSONObject][kNRMA_CR_platformKey] isEqualToString:NRMA_OSNAME_TVOS]);
#else
    XCTAssertTrue([[report JSONObject][kNRMA_CR_platformKey] isEqualToString:NRMA_OSNAME_IOS]);
#endif

}



@end
