//
//  NRMATraceTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/8/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAHTTPTransactionMeasurement.h"
#import "NRMATrace.h"
#import "NewRelicAgentInternal.h"
#import <OCMock/OCMock.h>
@interface NRMATraceTest : XCTestCase

@end

@implementation NRMATraceTest

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}


- (void) testBadNetworkTransactionRejection
{
    NSDate* date = [NSDate date];
    id internalMock = [OCMockObject niceMockForClass:[NewRelicAgentInternal class]];
    [[[[internalMock stub] andReturn:internalMock] classMethod] sharedInstance];
    [[[internalMock stub] andReturn:date] getAppSessionStartDate];

    NRMAHTTPTransactionMeasurement* transaction = [[NRMAHTTPTransactionMeasurement alloc] initWithURL:@"google.com"
                                                                                           httpMethod:@"GET"
                                                                                              carrier:@"wifi"
                                                                                            startTime:1
                                                                                            totalTime:200
                                                                                           statusCode:200
                                                                                            errorCode:0
                                                                                            bytesSent:10
                                                                                        bytesReceived:10
                                                                                              appData:nil
                                                                                              wanType:nil
                                                                                           threadInfo:[[NRMAThreadInfo alloc]init]];
    NRMATrace* rootTrace = [[NRMATrace alloc] init];
    [rootTrace consumeMeasurement:transaction];
    XCTAssertEqual(0,[rootTrace.scopedMeasurements count], @"");

    transaction = [[NRMAHTTPTransactionMeasurement alloc] initWithURL:@"google.com"
                                                           httpMethod:@"GET"
                                                              carrier:@"wifi"
                                                            startTime:([date timeIntervalSince1970]+10) *1000
                                                            totalTime:200
                                                           statusCode:200
                                                            errorCode:0
                                                            bytesSent:10
                                                        bytesReceived:10
                                                              appData:nil
                                                              wanType:nil
                                                           threadInfo:[[NRMAThreadInfo alloc]init]];

    [rootTrace consumeMeasurement:transaction];
    XCTAssertEqual(1, [rootTrace.scopedMeasurements count], @"");


    [internalMock stopMocking];
}
- (void) testExclusiveTime
{
    NRMATrace* rootTrace = [[NRMATrace alloc] init];
    NRMATrace* aSubTrace;
    rootTrace.entryTimestamp = 0;
    rootTrace.exitTimestamp = 100;
    rootTrace.threadInfo = [[NRMAThreadInfo alloc] init];
    for (int i =0 ; i < 4; i++) {
        NRMATrace* subTrace = [[NRMATrace alloc] init];
        subTrace.entryTimestamp = 10*(2+i);
        subTrace.exitTimestamp = subTrace.entryTimestamp + 7;
        if (i == 3) {
            for (int j = 0; j<3; j++) {
                NRMATrace* subsubTrace = [[NRMATrace alloc] init];
                subsubTrace.entryTimestamp = subTrace.entryTimestamp + (1 + j);
                subsubTrace.exitTimestamp = subsubTrace.entryTimestamp + 1;
                subsubTrace.threadInfo = [[NRMAThreadInfo alloc] init];
                [subTrace.children addObject:subsubTrace];
                [subsubTrace calculateExclusiveTime];
            }
            [subTrace calculateExclusiveTime];
            aSubTrace = subTrace;
        }
        [rootTrace.children addObject:subTrace];
    }
    
    
    [rootTrace calculateExclusiveTime];
    
    XCTAssertTrue(rootTrace.exclusiveTimeMillis == (100 - 28), @"verify exlusive time works");
    
    XCTAssertTrue(aSubTrace.exclusiveTimeMillis == (7 - 3), @"subtrace should reflect proper exclusivetime");
    
    XCTAssertTrue(((NRMATrace*)aSubTrace.children.anyObject).exclusiveTimeMillis == 1, @"this has no subtraces.");
}




@end
