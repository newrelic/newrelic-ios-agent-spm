//
//  NRMAHarvestableHTTPReqeustTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 11/4/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "NewRelicInternalUtils.h"
#import "NRMAmeasurements.h"
#import "NRMAHarvestableHTTPTransactionGeneration.h"
#import "NewRelic.h"
#import "NRMAMeasurementEngine.h"
#import "NRMAHTTPTransactionMeasurement.h"
#import "NRMAHarvestController.h"
#import "NRMATaskQueue.h"
#import "NRMAHarvesterConfiguration.h"
@interface NRMAHarvestableHTTPReqeustTests : XCTestCase

@end

@implementation NRMAHarvestableHTTPReqeustTests

- (void)setUp {
    [super setUp];
    [NRMAMeasurements initializeMeasurements];
}

- (void)tearDown {
    [NRMAMeasurements shutdown];
    [super tearDown];
}

- (void) testWanTypeInHarvestController
{
    __block BOOL completed = NO;
    NRTimer* timer = [NewRelic createAndStartTimer];
    __block NRMAHarvestableHTTPTransaction* measurement = nil;
    id mockUtils = [OCMockObject mockForClass:[NewRelicInternalUtils class]];
    [[[[mockUtils stub] classMethod] andReturn:@"CDMA"] getCurrentWanType];

    id mockHarvestableHTTPTransactionGeneration = [OCMockObject mockForClass:[NRMAHarvestController class]];


    [[[[mockHarvestableHTTPTransactionGeneration stub] classMethod] andDo:^(NSInvocation * invoke) {
        NRMAHarvestableHTTPTransaction* localMeasurement;
        [invoke getArgument:&localMeasurement atIndex:2];
        measurement = [localMeasurement retain];
        completed = YES;
    }] addHarvestableHTTPTransaction:OCMOCK_ANY];

    [NewRelic noticeNetworkRequestForURL:[NSURL URLWithString:@"google.com"]
                              httpMethod:@"post"
                               withTimer:timer
                         responseHeaders:nil
                              statusCode:200
                               bytesSent:1024
                           bytesReceived:1023
                            responseData:nil
                               andParams:nil];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //test timed out.
        completed = YES;
    });
    while (CFRunLoopGetCurrent() && !completed) {
    }
    [mockUtils stopMocking];
    [mockHarvestableHTTPTransactionGeneration stopMocking];

    XCTAssertNotNil(measurement,@"measurement is nil. mockHarvestableHTTPTransactionGeneration is not getting metrics");
    XCTAssertTrue([measurement.url isEqualToString:@"google.com"],@"url %@ doesn't match sent url",measurement.url);
    XCTAssertTrue(measurement.statusCode == 200,@"statusCode %d doesn't match sent status code",measurement.statusCode);
    XCTAssertTrue(measurement.bytesSent == 1024,@"bytesSent %lld doesn't max sent bytesSent",measurement.bytesSent);
    XCTAssertTrue(measurement.bytesReceived == 1023,@"bytesReceived %lld doesn't match bytesReceived",measurement.bytesReceived);
    XCTAssertTrue([measurement.wanType isEqualToString:@"CDMA"],@"measurement.wanType %@ doesn't match expected connection type",measurement.wanType);
}

- (void) testConnectionErrorInHarvestController
{
    __block BOOL completed = NO;
    NRTimer* timer = [NewRelic createAndStartTimer];
    __block NRMAHarvestableHTTPError* measurement = nil;

    id mockUtils = [OCMockObject mockForClass:[NewRelicInternalUtils class]];
    [[[[mockUtils stub] classMethod] andReturn:@"CDMA"] getCurrentWanType];

    id harvestController = [OCMockObject mockForClass:[NRMAHarvestController class]];

    [[[[harvestController stub] classMethod] andDo:^(NSInvocation *invoke) {
        NRMAHarvestableHTTPError* localError;
        [invoke getArgument:&localError atIndex:2];
        measurement = [localError retain];
        completed = YES;
    }] addHarvestableHTTPError:OCMOCK_ANY];


    [[[harvestController stub] andReturn:[NRMAHarvesterConfiguration defaultHarvesterConfiguration] ] configuration];
    [NewRelic noticeNetworkRequestForURL:[NSURL URLWithString:@"google.com"]
                              httpMethod:@"post"
                               withTimer:timer
                         responseHeaders:nil
                              statusCode:400
                               bytesSent:1024
                           bytesReceived:1023
                            responseData:nil
                               andParams:nil];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //test timed out.
        completed = YES;
    });
    while (CFRunLoopGetCurrent() && !completed) {}

    [harvestController stopMocking];
    [mockUtils stopMocking];

    XCTAssertNotNil(measurement,@"measurement is nil. mockHarvestableHTTPTransactionGeneration is not getting metrics");
    XCTAssertTrue(((NSString*)measurement.parameters[@"custom_params"][@"wan_type"]).length > 0 );
    XCTAssertTrue([measurement.url isEqualToString:@"google.com"],@"url %@ doesn't match sent url",measurement.url);
    XCTAssertTrue(measurement.statusCode == 400,@"statusCode %d doesn't match sent status code",measurement.statusCode);
}
@end
