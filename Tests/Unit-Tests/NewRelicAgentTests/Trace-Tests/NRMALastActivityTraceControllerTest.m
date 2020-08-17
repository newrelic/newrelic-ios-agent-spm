//
//  NRMALastActivityTraceControllerTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 7/8/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMALastActivityTraceController.h"

@interface NRMALastActivityTraceController()
+ (NRMAInteractionDataStamp*) lastExecutedActivity;
@end

@interface NRMALastActivityTraceControllerTest : XCTestCase

@end

static NSString const * kNRMADefaultName = @"test";
static const double kNRMADefaultDuration = 1;
static const double kNRMADefaultStartTime = 1;

@implementation NRMALastActivityTraceControllerTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [NRMALastActivityTraceController storeLastActivityStampWithName:(NSString*)kNRMADefaultName
                                                     startTimestamp:[NSNumber numberWithDouble:kNRMADefaultStartTime]
                                                           duration:[NSNumber numberWithDouble:kNRMADefaultStartTime]];
}


- (void) testLastExecutedActivityCopy
{
    NRMAInteractionDataStamp* dataStamp = [NRMALastActivityTraceController copyLastActivityStamp];
    XCTAssertFalse(dataStamp == [NRMALastActivityTraceController lastExecutedActivity], @"objects shouldn't be the same");

    XCTAssertTrue([dataStamp isEqual:[NRMALastActivityTraceController lastExecutedActivity]], @"data should match");
}


- (void) testClearLastActivityStamp
{
    XCTAssertTrue([NRMALastActivityTraceController lastExecutedActivity], @"should not be nil");

    [NRMALastActivityTraceController clearLastActivityStamp];

    XCTAssertNil([NRMALastActivityTraceController lastExecutedActivity],@"should be nil");
}

- (void) testStoreLastActivityStamp
{
    NRMAInteractionDataStamp* stamp = [NRMALastActivityTraceController lastExecutedActivity];

    XCTAssertTrue([stamp.name isEqualToString:(NSString*)kNRMADefaultName], @"stamp.name (\"%@\") should equal %@",stamp.name, kNRMADefaultName);
    XCTAssertTrue(stamp.duration.doubleValue == kNRMADefaultDuration , @"stamp.duration (\"%@\") should eqaul %f",stamp.duration, kNRMADefaultDuration);
    XCTAssertTrue(stamp.startTimestamp.doubleValue == kNRMADefaultStartTime, @"stamp.startTimestamp (\"%@\") should be equal %f", stamp.startTimestamp, kNRMADefaultStartTime);

    NSString* name = @"Hello World";
    NSNumber* duration = @100;
    NSNumber* startTime = @123;

    [NRMALastActivityTraceController storeLastActivityStampWithName:name startTimestamp:startTime duration:duration];


    XCTAssertTrue([stamp.name isEqualToString:name], @"stamp.name (\"%@\") should equal %@",stamp.name, name);
    XCTAssertTrue(stamp.duration.doubleValue ==  duration.doubleValue , @"stamp.duration (\"%@\") should eqaul %@",stamp.duration, duration);
    XCTAssertTrue(stamp.startTimestamp.doubleValue == startTime.doubleValue, @"stamp.startTimestamp (\"%@\") should be equal %@",stamp.startTimestamp, startTime);
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


@end
