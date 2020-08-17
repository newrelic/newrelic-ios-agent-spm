//
//  NRMAAPIHelperTests.m
//  NewRelicAgent
//
//  Created by Paul Knudsen on 11/28/16.
//  Copyright © 2016 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NewRelic.h"
#import "NewRelicAgentInternal.h"

@interface NRMAAPIHelperTests: XCTestCase

@end

@implementation NRMAAPIHelperTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
    [NRMAAnalytics clearDuplicationStores];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void) testSetUserId {
        NRMAAnalytics* analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:0];
    //- (BOOL) setUserId:(NSString*)userId
        XCTAssert([analytics setUserId:@"AUniqueId1"], @"Good input produced incorrect result");
        
        XCTAssertFalse([analytics setUserId:nil], @"bad input produced a incorrect result");
        
        XCTAssertFalse([analytics setUserId:@""], @"bad input produced a incorrect result");
}
@end
