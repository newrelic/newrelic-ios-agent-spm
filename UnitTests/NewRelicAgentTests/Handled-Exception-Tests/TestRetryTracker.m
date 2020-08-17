//
//  TestRetryTracker.m
//  NewRelic
//
//  Created by Bryce Buchanan on 7/26/17.
//  Copyright (c) 2017 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMARetryTracker.h"

@interface TestRetryTracker : XCTestCase
@property (strong) NRMARetryTracker* tracker;
@property unsigned int retries;
@end

@implementation TestRetryTracker

- (void)setUp {
    [super setUp];
    self.retries = 3;
    self.tracker = [[NRMARetryTracker alloc] initWithRetryLimit:self.retries];
}

- (void)tearDown {
    [super tearDown];
    self.tracker = nil;
}

- (void) testNullValues {
    XCTAssertNoThrow([self.tracker shouldRetryTask:nil]);
    XCTAssertNoThrow([self.tracker untrack:nil]);
    XCTAssertNoThrow([self.tracker track:nil]);
}

- (void) testRetryNonTracked {
    NSNumber* value = @(5.0f);
    XCTAssertFalse([self.tracker shouldRetryTask:value]);
}

- (void) testRetries {
    NSNumber* value = @(5.0f);

    [self.tracker track:value];

    XCTAssertTrue([self.tracker shouldRetryTask:value]);
    XCTAssertTrue([self.tracker shouldRetryTask:value]);
    XCTAssertTrue([self.tracker shouldRetryTask:value]);

    XCTAssertFalse([self.tracker shouldRetryTask:value]);
    XCTAssertFalse([self.tracker shouldRetryTask:value]);
    XCTAssertFalse([self.tracker shouldRetryTask:value]);
}

- (void) testUnTrack {
    NSNumber* value = @(5.0f);
    [self.tracker track:value];
    XCTAssertTrue([self.tracker shouldRetryTask:value]);
    [self.tracker untrack:value];
    XCTAssertFalse([self.tracker shouldRetryTask:value]);
}

@end
