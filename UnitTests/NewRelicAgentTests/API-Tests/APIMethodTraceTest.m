//
//  APIMethodTraceTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 11/7/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAMeasurements.h"
#import "NRMeasurementConsumerHelper.h"
#import "NRMATraceController.h"
#import "NRMAHarvestController.h"
#import "NRMAActivityTraceMeasurement.h"
#import <OCMock/OCMock.h>
#import "NRMATaskQueue.h"
#import "NewRelic.h"
@interface NRMATaskQueue ()
+ (NRMATaskQueue*) taskQueue;
+ (void) clear;
@end

@interface APIMethodTraceTest : XCTestCase
{
    NRMAMeasurementConsumerHelper* helper;
    id harvestConfigurationObject;
}
@end
@interface NRMATraceController ()
+ (BOOL) newTraceSetup:(NRMATrace*)newTrace
           parentTrace:(NRMATrace*)parentTrace;
+ (void) exitMethodWithTimestampMillis:(double)millis;
@end

@implementation APIMethodTraceTest

- (void)setUp
{
    [super setUp];
    helper = [[NRMAMeasurementConsumerHelper alloc] initWithType:NRMAMT_Activity];

    [NRMAMeasurements initializeMeasurements];
    [NRMAMeasurements addMeasurementConsumer:helper];

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
    [NRMAMeasurements removeMeasurementConsumer:helper];
    [NRMAMeasurements shutdown];
    [harvestConfigurationObject stopMocking];
    [super tearDown];
}










@end
