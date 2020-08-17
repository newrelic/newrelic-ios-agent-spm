//
//  NRMAHarvestableEventsTest.m
//  NewRelic
//
//  Created by Bryce Buchanan on 2/10/15.
//  Copyright (c) 2015 New Relic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NRMAAnalyticsEvents.h"
#import "NRMAHarvesterConfiguration.h"
#import "NRMAHarvestController.h"
#import <XCTest/XCTest.h>


@interface NRMAHarvestableEventsTest : XCTestCase
{
    NSArray * expectedJSON;
}
@property(strong) NRMAAnalyticsEvents* events;
@end

@implementation NRMAHarvestableEventsTest

- (void)setUp {
    [super setUp];
    self.events = [NRMAAnalyticsEvents new];
    expectedJSON = @[@{@"blah":@"blah"},@{@"pewpew":@4.4},@{@"event":@10,@"asdf":@"asdf",@"123":@123}];
    [self.events addEvents:expectedJSON];
}

- (void)tearDown {
    self.events = nil;
    [super tearDown];
}


- (void) testAddEvents {
    XCTAssertTrue([self.events count] == 3, @"we just added 3 events.");

   NSArray* json = [self.events JSONObject];

    for (int i = 0; i < expectedJSON.count; i++) {
        for (id obj in [expectedJSON[i] allKeys]) {
            XCTAssertTrue([expectedJSON[i][obj] isEqual:json[i][obj]],@"expected json is not equal to actual output: json[%@] = %@ doesn't match expectedJSON[%@] = %@",obj,json[i][obj],obj,expectedJSON[i][obj]);
        }
    }

    [self.events clear];

    XCTAssertTrue(self.events.count == 0, @"expected clear to remove all events.");

    XCTAssertNoThrow([self.events addEvents:nil], @"nil shouldn't throw.");
}


- (void) testEventAgedOutWithHarvestBefore
{
    XCTAssertTrue([self.events count] == 3, @"we just added 3 events.");

    NRMAHarvesterConfiguration *config = [NRMAHarvestController configuration];
    int maxSendAttempts = config.activity_trace_max_send_attempts; //this is 0

    for (int i = 0; i < maxSendAttempts+1; i++){
        [self.events onHarvestBefore];
    }

    XCTAssertTrue(self.events.count == 0, @"our data should have aged out.");
}


- (void) testEventAgedOutWithHarvestError
{
    XCTAssertTrue([self.events count] == 3, @"we just added 3 events.");

    NRMAHarvesterConfiguration *config = [NRMAHarvestController configuration];
    int maxSendAttempts = config.activity_trace_max_send_attempts; //this is 0

    for (int i = 0; i < maxSendAttempts+1; i++){
        [self.events onHarvestError];
    }

    XCTAssertTrue(self.events.count == 0, @"our data should have aged out.");
}
@end
