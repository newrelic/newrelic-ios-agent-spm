//
//  NRMAUpgradeMetricGeneratorTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/22/15.
//  Copyright © 2015 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAAppUpgradeMetricGenerator.h"
#import "NRMATaskQueue.h"
#import "NRMAMetric.h"
#import "NRConstants.h"
#import <OCMock/OCMock.h>
#import "NRMABool.h"
#import "NRMAAnalytics.h"
#import <Analytics/Constants.hpp>

@interface NRMAUpgradeMetricGeneratorTest : XCTestCase

@end

@implementation NRMAUpgradeMetricGeneratorTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void) testMetricGeneration {
    __block BOOL didQueue = NO;
    __block NSString* lastVersion = @"5.0";
    id mockQueue = [OCMockObject mockForClass:[NRMATaskQueue class]];
    [[[[mockQueue expect] classMethod] andDo:^(NSInvocation *invocation) {
        __autoreleasing NRMAMetric* metric = nil;
        [invocation getArgument:&metric atIndex:2];
        XCTAssertTrue([metric.name isEqualToString:@"Mobile/App/Upgrade"], @"invalid metric name");
        XCTAssertEqual(@1, metric.value, @"invalid metric value.");
        didQueue = YES;
    }] queue:OCMOCK_ANY];


    NRMAAppUpgradeMetricGenerator* metricGenerator = [NRMAAppUpgradeMetricGenerator new];


    [[NSNotificationCenter defaultCenter] postNotificationName:kNRMADidChangeAppVersionNotification
                                                        object:nil
                                                      userInfo:@{kNRMALastVersionKey : lastVersion,
                                                                 kNRMACurrentVersionKey: @"5.1"}];

    //simulate a harvest
    [metricGenerator onHarvestBefore];

    while (!didQueue && CFRunLoopGetCurrent()) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }


    [mockQueue verify];
    [mockQueue stopMocking];
}
// re-enable tests when analytics accepts true bool values.
- (void) testAttributeGenerationAnalyticSecond {
    __block NSString* lastVersion = @"5.0";
    __block BOOL sessionAttributeAdded = NO;
    NRMAAppUpgradeMetricGenerator* metricGenerator = [NRMAAppUpgradeMetricGenerator new];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNRMADidChangeAppVersionNotification
                                                        object:nil
                                                      userInfo:@{kNRMALastVersionKey : lastVersion,
                                                                 kNRMACurrentVersionKey: @"5.1"}];
    
    NRMAAnalytics* analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:[NSDate timeIntervalSinceReferenceDate]];

    id mockAnalytics = [OCMockObject partialMockForObject:analytics];


    [[[mockAnalytics expect] andDo:^(NSInvocation *invocation) {
        __autoreleasing NSString* attribute = nil;
        __autoreleasing NSString* value = nil;

        [invocation getArgument:&attribute atIndex:2];
        [invocation getArgument:&value atIndex:3];

        XCTAssertTrue([lastVersion isEqualToString:value], @"verison value doesn't match");
        XCTAssertTrue([@(__kNRMA_RA_upgradeFrom) isEqualToString:attribute],@"incorrect attribute string.");


        sessionAttributeAdded = YES;
    }]setNRSessionAttribute:OCMOCK_ANY value:OCMOCK_ANY];

    [[NSNotificationCenter defaultCenter] postNotificationName:kNRMAAnalyticsInitializedNotification
                                                        object:nil
                                                      userInfo:@{kNRMAAnalyticsControllerKey : mockAnalytics}];

    while (!sessionAttributeAdded && CFRunLoopGetCurrent()) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }


    [mockAnalytics verify];
    [mockAnalytics stopMocking];
    metricGenerator = nil;
}

- (void) testAttributeGenerateAnalyticFirst {
    __block NSString* lastVersion = @"5.0";
    __block BOOL sessionAttributeAdded = NO;
    NRMAAppUpgradeMetricGenerator* metricGenerator = [NRMAAppUpgradeMetricGenerator new];

    NRMAAnalytics* analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:[NSDate timeIntervalSinceReferenceDate]];

    id mockAnalytics = [OCMockObject partialMockForObject:analytics];


    [[[mockAnalytics expect] andDo:^(NSInvocation *invocation) {
        __autoreleasing NSString* attribute = nil;
        __autoreleasing NSString* value = nil;

        [invocation getArgument:&attribute atIndex:2];
        [invocation getArgument:&value atIndex:3];

        XCTAssertTrue([lastVersion isEqualToString:value], @"verison value doesn't match");
        XCTAssertTrue([@(__kNRMA_RA_upgradeFrom) isEqualToString:attribute],@"incorrect attribute string.");


        sessionAttributeAdded = YES;
    }]setNRSessionAttribute:OCMOCK_ANY value:OCMOCK_ANY];


    [[NSNotificationCenter defaultCenter] postNotificationName:kNRMAAnalyticsInitializedNotification
                                                        object:nil
                                                      userInfo:@{kNRMAAnalyticsControllerKey : mockAnalytics}];

    [[NSNotificationCenter defaultCenter] postNotificationName:kNRMADidChangeAppVersionNotification
                                                        object:nil
                                                      userInfo:@{kNRMALastVersionKey : lastVersion,
                                                                 kNRMACurrentVersionKey: @"5.1"}];
    

    while (!sessionAttributeAdded && CFRunLoopGetCurrent()) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }


    [mockAnalytics verify];
    [mockAnalytics stopMocking];
    metricGenerator = nil;
}


- (void) testDeviceChangeOccured {
    __block BOOL sessionAttributeAdded = NO;
    NRMAAppUpgradeMetricGenerator* metricGenerator = [NRMAAppUpgradeMetricGenerator new];

    NRMAAnalytics* analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:[NSDate timeIntervalSinceReferenceDate]];

    id mockAnalytics = [OCMockObject partialMockForObject:analytics];


    [[[mockAnalytics expect] andDo:^(NSInvocation *invocation) {
        __autoreleasing NSString* attribute = nil;
        __autoreleasing NRMABool* value = nil;

        [invocation getArgument:&attribute atIndex:2];
        [invocation getArgument:&value atIndex:3];

        XCTAssertTrue([attribute stringByAppendingString:kNRMADeviceChangedAttribute]);
        XCTAssertTrue(value.value, @"device didn't change.");


        sessionAttributeAdded = YES;
    }]setNRSessionAttribute:OCMOCK_ANY value:OCMOCK_ANY];


    [[NSNotificationCenter defaultCenter] postNotificationName:kNRMAAnalyticsInitializedNotification
                                                        object:nil
                                                      userInfo:@{kNRMAAnalyticsControllerKey : mockAnalytics}];

    [[NSNotificationCenter defaultCenter] postNotificationName:kNRMADeviceDidChangeNotification
                                                        object:nil
                                                      userInfo:nil];

    

    while (!sessionAttributeAdded && CFRunLoopGetCurrent()) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }


    [mockAnalytics verify];
    [mockAnalytics stopMocking];
    metricGenerator = nil;

}

- (void) testdeviceChangeAnalyticSecond {
    __block BOOL sessionAttributeAdded = NO;
    NRMAAppUpgradeMetricGenerator* metricGenerator = [NRMAAppUpgradeMetricGenerator new];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNRMADeviceDidChangeNotification
                                                        object:nil
                                                      userInfo:nil];

    NRMAAnalytics* analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:[NSDate timeIntervalSinceReferenceDate]];

    id mockAnalytics = [OCMockObject partialMockForObject:analytics];


    [[[mockAnalytics expect] andDo:^(NSInvocation *invocation) {
        __autoreleasing NSString* attribute = nil;
        __autoreleasing NRMABool* value = nil;

        [invocation getArgument:&attribute atIndex:2];
        [invocation getArgument:&value atIndex:3];

        XCTAssertTrue([attribute isEqualToString:kNRMADeviceChangedAttribute]);
        XCTAssertTrue(value.value);


        sessionAttributeAdded = YES;
    }]setNRSessionAttribute:OCMOCK_ANY value:OCMOCK_ANY];

    [[NSNotificationCenter defaultCenter] postNotificationName:kNRMAAnalyticsInitializedNotification
                                                        object:nil
                                                      userInfo:@{kNRMAAnalyticsControllerKey : mockAnalytics}];

    while (!sessionAttributeAdded && CFRunLoopGetCurrent()) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }


    [mockAnalytics verify];
    [mockAnalytics stopMocking];
    metricGenerator = nil;
}

@end
