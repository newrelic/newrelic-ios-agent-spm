//
//  NewRelicAPITest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/11/17.
//  Copyright © 2017 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <NewRelic/NewRelic.h>
#import <OCMock/OCMock.h>
#import "NRMAAnalytics.h"
#import "NewRelicAgentInternal.h"
@interface NewRelicAPITest : XCTestCase
@property(strong) NRMAAnalytics* analyticsController; //will auto-nil if released (yay)
@property(strong) id mockAgentInternal;
@end

@implementation NewRelicAPITest

- (void)setUp {
    [super setUp];
    self.analyticsController = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:0];

    self.mockAgentInternal = [OCMockObject niceMockForClass:[NewRelicAgentInternal class]];

    [[[[self.mockAgentInternal stub] classMethod] andReturn:self.mockAgentInternal] sharedInstance];

    [[[self.mockAgentInternal stub] andReturn:self.analyticsController] analyticsController];




    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    [self.mockAgentInternal stopMocking];
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testRecordCustomEventWithName {
    XCTAssertTrue([NewRelic recordCustomEvent:@"asdf"
                                   attributes:nil]);
    XCTAssertTrue([NewRelic recordCustomEvent:@"asdf"
                                         name:nil
                                   attributes:nil]);
    XCTAssertTrue([NewRelic recordCustomEvent:@"asdf"
                                         name:@"blah"
                                   attributes:@{@"name":@"unblah"}]);
}


@end
