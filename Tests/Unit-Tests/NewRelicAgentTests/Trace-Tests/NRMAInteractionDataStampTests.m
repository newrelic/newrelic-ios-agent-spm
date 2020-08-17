//
//  NRMAInteractionDataStampTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 7/8/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAInteractionDataStamp.h"
@interface NRMAInteractionDataStampTests : XCTestCase
{
    NRMAInteractionDataStamp* stamp;
}
@end

static NSString const * kNRMADefaultName = @"test";
static const double kNRMADefaultDuration = 1;
static const double kNRMADefaultStartTime = 1;

@implementation NRMAInteractionDataStampTests

- (void)setUp
{
    [super setUp];
    stamp = [[NRMAInteractionDataStamp alloc] init];
    stamp.name = (NSString*)kNRMADefaultName;
    stamp.duration = [NSNumber numberWithDouble:kNRMADefaultDuration];
    stamp.startTimestamp = [NSNumber numberWithDouble:kNRMADefaultStartTime];
}

- (void) testIsEqual
{


    NRMAInteractionDataStamp* testStamp = [[NRMAInteractionDataStamp alloc] init];
    testStamp.name = (NSString*)kNRMADefaultName;
    testStamp.duration = [NSNumber numberWithDouble:kNRMADefaultDuration];
    testStamp.startTimestamp = [NSNumber numberWithDouble:kNRMADefaultStartTime];

    XCTAssertEqualObjects(testStamp, stamp, @"testStamp (\"%@\") and stamp (\"%@\") should be equal",testStamp,stamp);
}

- (void) testJSON
{

    NSDictionary* typeDict = @{@"type":@"ACTIVITY_HISTORY"};
    int typeIndex = 0;
    int nameIndex = 1;
    int startTimeIndex = 2;
    int durationIndex = 3;
    NSArray* json = [stamp JSONObject];

    XCTAssertEqualObjects(json[typeIndex], typeDict, @"the type dictionaries should match");
    XCTAssertEqualObjects(json[nameIndex], stamp.name, @"the json name (\"%@\") doesn't match %@",json[nameIndex],stamp.name);
    XCTAssertEqualObjects(json[startTimeIndex], stamp.startTimestamp, @"the json startTime (\"%@\") doesn't equal %@",json[startTimeIndex],stamp.startTimestamp);
    XCTAssertEqualObjects(json[durationIndex], stamp.duration, @"the json duration (\"%@\") doesn't equal %@",json[durationIndex],stamp.duration);
}

- (void) testCopy
{
    NRMAInteractionDataStamp* testStamp = [stamp copy];
    XCTAssertEqualObjects(testStamp, stamp, @"these should be equal");
    XCTAssertFalse(testStamp == stamp, @"these shouldn't be the same object");
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    stamp = nil;
    [super tearDown];
}

@end
