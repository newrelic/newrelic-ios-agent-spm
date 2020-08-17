//
//  NRMAMeasurementTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/23/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMeasurementTest.h"
#import "NRMAMeasurementType.h"
@implementation NRMAMeasurementTest



- (void) setUp
{
    measurement = [[NRMAMeasurement alloc] initWithType:NRMAMT_Activity];
}

- (void) testGetMeasurementType
{
    XCTAssertTrue(NRMAMT_Activity == measurement.type, @"");
}

- (void) testIsInstantaneous
{
    measurement  = [[NRMAMeasurement alloc] initWithType:NRMAMT_Activity];
    measurement.startTime = [[NSNumber numberWithDouble:([[NSDate date] timeIntervalSince1970] *1000)] longLongValue];
    XCTAssertTrue(measurement.isInstantaneous, @"");
    
    measurement.endTime = [[NSNumber numberWithDouble:([[NSDate date] timeIntervalSince1970] *1000)] longLongValue];
    XCTAssertFalse(measurement.isInstantaneous, @"");
}

- (void) testInvalidEndTime
{
    
    measurement.startTime =  [[NSNumber numberWithDouble:([[NSDate date] timeIntervalSince1970] *1000)] longLongValue];
    @try {
        measurement.endTime = -1000;
    }
    @catch (NSException *exception) {
        XCTAssertEqual(exception.name, NSInvalidArgumentException, @"");
    }
    XCTAssertTrue(measurement.endTime == 0 , @"");
}

- (void) testFinish
{
    [measurement finish];
    XCTAssertTrue(measurement.isFinished, @"");
    
    XCTAssertThrows([measurement finish], @"cannot finish a finished measurement");
    
}

- (void) testImmutableAfterFinish
{
    [measurement finish];
    XCTAssertThrows(measurement.endTime = [[NSNumber numberWithDouble:([[NSDate date] timeIntervalSince1970] *1000)] longValue], @"cannont edit a finished measurement");
}

- (void) testThread
{
    measurement.threadInfo = [[NRMAThreadInfo alloc] init];
    
    NRMAMeasurement* measurement2 = [[NRMAMeasurement alloc] initWithType:NRMAMT_Activity];
    measurement2.threadInfo = [[NRMAThreadInfo alloc] init];
    
    XCTAssertTrue(measurement.threadInfo.identity == measurement2.threadInfo.identity, @"thread identity should match");
}
@end
