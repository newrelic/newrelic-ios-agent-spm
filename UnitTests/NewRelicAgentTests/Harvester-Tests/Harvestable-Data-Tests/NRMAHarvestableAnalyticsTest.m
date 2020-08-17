//
//  NRMAHarvestableAnalyticsTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/30/15.
//  Copyright (c) 2015 New Relic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NRMAHarvestableAnalytics.h"
#import <XCTest/XCTest.h>

@interface NRMAHarvestableAnalyticsTest : XCTestCase

@end

@implementation NRMAHarvestableAnalyticsTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}
- (void) testInvalidJson {
    XCTAssertNoThrow([[NRMAHarvestableAnalytics alloc] initWithAttributeJSON:nil
                                                  EventJSON:nil]);

    NRMAHarvestableAnalytics* harvestableAnalytics = [[NRMAHarvestableAnalytics alloc] initWithAttributeJSON:nil EventJSON:nil];
    XCTAssertEqual(harvestableAnalytics.events.count, 0,@"");
    XCTAssertEqual(harvestableAnalytics.sessionAttributes.count, 0,@"");


}

@end
