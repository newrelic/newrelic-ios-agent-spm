//
//  NRMATimestampContainerTest.m
//  NRMA Stress Tests
//
//  Created by Bryce Buchanan on 10/18/17.
//  Copyright © 2017 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMATimestampContainer.h"

@interface NRMATimestampContainerTest : XCTestCase

@end

@implementation NRMATimestampContainerTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testCanery {
    //at some point, our timestamps will increase an order of magnitude (Saturday, November 20, 2286 5:46:40 PM +000)
    //this may require some fixes to accomodate (lol, y2k)
    double distanceFutureTimestamp = 10000000000;

    BOOL val = [NRMATimestampContainer findUnits:distanceFutureTimestamp] != NRMATU_UNKWN;
    XCTAssertFalse(val);
}

- (void) testTimestampContainer {
    double timestampMillis = 1508368825000;
    double timestampSec = 1508368825;

    NRMATimestampContainer* tc1 = [[NRMATimestampContainer alloc] initWithTimestamp:timestampMillis];
    NRMATimestampContainer* tc2 = [[NRMATimestampContainer alloc] initWithTimestamp:timestampSec];

    XCTAssertEqualWithAccuracy(tc1.timestamp, timestampMillis, 0.001);
    XCTAssertEqualWithAccuracy(tc2.timestamp, timestampSec, 0.001);

    XCTAssertTrue(tc1.units == NRMATU_MILLI);
    XCTAssertTrue(tc2.units == NRMATU_SEC);

    XCTAssertTrue([tc1 toSeconds] - [tc2 toSeconds] == 0);
    XCTAssertTrue([tc1 toMilliseconds] - [tc2 toMilliseconds] == 0);

}

- (void) testManualUnits {
    double timestamp = 1234567890;
    NRMATimestampContainer* tc1 = [[NRMATimestampContainer alloc] initWithTimestamp:timestamp units:NRMATU_SEC];

    NSDate* d1 = [NSDate dateWithTimeIntervalSince1970:timestamp];

    XCTAssertEqualWithAccuracy([d1 timeIntervalSince1970], [tc1 toSeconds], .01);

    XCTAssertEqualWithAccuracy(timestamp*1000, tc1.toMilliseconds, .01);


    NRMATimestampContainer* tc2 = [[NRMATimestampContainer alloc] initWithTimestamp:timestamp units :NRMATU_MILLI];

    NSDate* d2 = [NSDate dateWithTimeIntervalSince1970:timestamp/1000];

    XCTAssertEqualWithAccuracy([d2 timeIntervalSince1970], [tc2 toSeconds], .01);

    XCTAssertEqualWithAccuracy(timestamp, [tc2 toMilliseconds], .01);


}

@end
