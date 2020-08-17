//
//  NRMAActivityTracesTest.m
//  NewRelicAgent
//
//  Created by Ben Weintraub on 11/6/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NRMAActivityTrace.h"
#import "NRMAActivityTraces.h"
#import "NRMAHarvestableTrace.h"
#import "NRMAHarvestableActivity.h"
#import "NRMAActivityTraceMeasurement.h"
#import "NRMAEnvironmentTraceSegment.h"
#import "NRMAHarvestableVitals.h"
#import "NRMAHarvestController.h"
#import <OCMock/OCMock.h>

@interface NRMAActivityTracesTest : XCTestCase
{
    id harvestConfigurationObject;
}
@end

@implementation NRMAActivityTracesTest

- (void)setUp
{
    [super setUp];
    harvestConfigurationObject = [OCMockObject niceMockForClass:[NRMAHarvestController class]];
    NRMAHarvesterConfiguration* config = [[NRMAHarvesterConfiguration alloc] init];
    config.collect_network_errors = YES;
    config.data_report_period= 60;
    config.error_limit = 3;
    config.report_max_transaction_age = 5;
    config.report_max_transaction_count = 2000;
    config.response_body_limit = 1024;
    config.stack_trace_limit = 2000;
    config.activity_trace_max_send_attempts = 2;
    config.activity_trace_min_utilization = .3;
    [[[harvestConfigurationObject stub] andReturn:config] configuration];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [NRMAHarvestController stop];
    [harvestConfigurationObject stopMocking];
    [super tearDown];
}

- (NRMAHarvestableActivity *)createHarvestableActivityTrace
{
    NRMAActivityTrace* trace = [[NRMAActivityTrace alloc] initWithRootTrace:[[NRMATrace alloc] init]];
    [trace complete];

    NRMAActivityTraceMeasurement* activityTrace = [[NRMAActivityTraceMeasurement alloc] initWithActivityTrace:trace];
    NRMAHarvestableActivity* harvestableActivity = [[NRMAHarvestableActivity  alloc] init];
    harvestableActivity.name = activityTrace.traceName;
    harvestableActivity.startTime = activityTrace.startTime;
    harvestableActivity.endTime = activityTrace.endTime;

    [harvestableActivity.childSegments addObject:[[NRMAHarvestableTrace alloc] initWithTrace:activityTrace.rootTrace]];

    return harvestableActivity;
}

- (void)testRemovesTracesThatHaveRepeatedlyFailed
{
    NRMAHarvestableActivity* trace0 = [self createHarvestableActivityTrace];
    NRMAHarvestableActivity* trace1 = [self createHarvestableActivityTrace];

    NRMAActivityTraces* traces = [[NRMAActivityTraces alloc] init];
    [traces.activityTraces addObjectsFromArray:@[trace0, trace1]];

    trace0.sendAttempts = 0;
    trace1.sendAttempts = 5;
    [traces onHarvestBefore];
    [traces onHarvestError];

    NSArray* actualTraces = traces.activityTraces;
    XCTAssertEqual([actualTraces count], ((NSUInteger)1), @"Expected exactly one trace left-over");
    XCTAssertEqual([actualTraces objectAtIndex:0], trace0, @"Expected trace with 0 sendAttempts to be left");
}

- (void)testIncrementsSendAttemptsOnActivityTraces
{
    NRMAHarvestableActivity* trace = [self createHarvestableActivityTrace];

    NRMAActivityTraces* traces = [[NRMAActivityTraces alloc] init];
    [traces.activityTraces addObject:trace];

    [traces onHarvestBefore];
    [traces onHarvestError];
    XCTAssertEqual([traces.activityTraces count], ((NSUInteger)1), @"Expected activity trace to still be present");
    XCTAssertEqual(trace.sendAttempts, ((NSUInteger)1), @"Expected sendAttempts to be equal to 1");

    [traces onHarvestBefore];
    [traces onHarvestError];
    XCTAssertEqual(trace.sendAttempts, ((NSUInteger)2), @"Expected sendAttempt to be equal to 2");
}

- (void)testRemovesTracesThatAreTooOld
{
    NRMAHarvestableActivity* trace0 = [self createHarvestableActivityTrace];
    NRMAHarvestableActivity* trace1 = [self createHarvestableActivityTrace];

    NRMAActivityTraces* traces = [[NRMAActivityTraces alloc] init];
    [traces.activityTraces addObjectsFromArray:@[trace0, trace1]];

    trace0.endTime = [[NSDate date] timeIntervalSince1970] - 3600; // one hour ago
    trace1.endTime = [[NSDate date] timeIntervalSince1970];        // now
    [traces onHarvestBefore];

    NSArray* actualTraces = traces.activityTraces;
    XCTAssertEqual([actualTraces count], ((NSUInteger) 1), @"Expected exactly one trace left-over");
    XCTAssertEqual([actualTraces objectAtIndex:0], trace1, @"Expected recent trace to be left");
}

@end
