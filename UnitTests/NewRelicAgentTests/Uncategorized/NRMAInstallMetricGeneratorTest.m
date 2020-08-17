//
//  NRMAInstallMetricGeneratorTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/22/15.
//  Copyright © 2015 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAAppInstallMetricGenerator.h"
#import "NRMATaskQueue.h"
#import "NRMAMetric.h"
#import "NRConstants.h"
#import <OCMock/OCMock.h>
#import "NRMAAnalytics.h"
#import <Analytics/Constants.hpp>
#import "NRMABool.h"

@interface NRMAInstallMetricGeneratorTest : XCTestCase

@end

@implementation NRMAInstallMetricGeneratorTest

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
    id mockQueue = [OCMockObject mockForClass:[NRMATaskQueue class]];
    [[[[mockQueue expect] classMethod] andDo:^(NSInvocation *invocation) {
        __autoreleasing NRMAMetric* metric = nil;
        [invocation getArgument:&metric atIndex:2];
        XCTAssertTrue([@"Mobile/App/Install" isEqualToString:metric.name], @"invalid metric name");
        XCTAssertEqual(@1, metric.value, @"invalid metric value.");
        didQueue = YES;
    }] queue:OCMOCK_ANY];


    NRMAAppInstallMetricGenerator* metricGenerator = [NRMAAppInstallMetricGenerator new];

    [[NSNotificationCenter defaultCenter] postNotificationName:kNRMADidGenerateNewUDIDNotification
                                                        object:nil
                                                      userInfo:@{@"UDID" : @"blah"}];

    //simulate a harvest
    [metricGenerator onHarvestBefore];

    while (!didQueue && CFRunLoopGetCurrent()) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }


    [mockQueue verify];
    [mockQueue stopMocking];
    metricGenerator = nil;
}

// re-enable tests when analytics accepts true bool values.
- (void) testAttributeGenerationAnalyticSecond {
    __block BOOL sessionAttributeAdded = NO;
    NRMAAppInstallMetricGenerator* metricGenerator = [NRMAAppInstallMetricGenerator new];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNRMADidGenerateNewUDIDNotification
                                                        object:nil
                                                      userInfo:@{@"UDID" : @"blah"}];
    
    NRMAAnalytics* analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:[NSDate timeIntervalSinceReferenceDate]];

    id mockAnalytics = [OCMockObject partialMockForObject:analytics];


    [[[mockAnalytics expect] andDo:^(NSInvocation *invocation) {
        __autoreleasing NSString* attribute = nil;
        __autoreleasing NRMABool* value = nil;

        [invocation getArgument:&attribute atIndex:2];
        [invocation getArgument:&value atIndex:3];

        XCTAssertTrue(value.value, @"verison value doesn't match");
        XCTAssertTrue([@(__kNRMA_RA_install) isEqualToString:attribute],@"incorrect attribute string.");


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
    __block BOOL sessionAttributeAdded = NO;
    NRMAAppInstallMetricGenerator* metricGenerator = [NRMAAppInstallMetricGenerator new];

    NRMAAnalytics* analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:[NSDate timeIntervalSinceReferenceDate]];

    id mockAnalytics = [OCMockObject partialMockForObject:analytics];

    [[[mockAnalytics expect] andDo:^(NSInvocation *invocation) {
        __autoreleasing NSString* attribute = nil;
        __autoreleasing NRMABool*   value = nil;

        [invocation getArgument:&attribute atIndex:2];
        [invocation getArgument:&value atIndex:3];

        XCTAssertTrue(value.value, @"version value doesn't match");
        XCTAssertTrue([@(__kNRMA_RA_install) isEqualToString:attribute],@"incorrect attribute string.");


        sessionAttributeAdded = YES;
    }]setNRSessionAttribute:OCMOCK_ANY value:OCMOCK_ANY];


    [[NSNotificationCenter defaultCenter] postNotificationName:kNRMAAnalyticsInitializedNotification
                                                        object:nil
                                                      userInfo:@{kNRMAAnalyticsControllerKey : mockAnalytics}];

    [[NSNotificationCenter defaultCenter] postNotificationName:kNRMADidGenerateNewUDIDNotification
                                                        object:nil
                                                      userInfo:@{@"UDID" : @"blah"}];

    while (!sessionAttributeAdded && CFRunLoopGetCurrent()) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }


    [mockAnalytics verify];
    [mockAnalytics stopMocking];

    metricGenerator = nil;
}

- (void) testGenerateNoSecureUDIDFirst {
    __block BOOL sessionAttributeAdded = NO;
    NRMAAppInstallMetricGenerator* metricGenerator = [NRMAAppInstallMetricGenerator new];

    NRMAAnalytics* analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:[NSDate timeIntervalSinceReferenceDate]];

    id mockAnalytics = [OCMockObject partialMockForObject:analytics];

    [[[mockAnalytics expect] andDo:^(NSInvocation *invocation) {
        __autoreleasing NSString* attribute = nil;
        __autoreleasing NRMABool*   value = nil;

        [invocation getArgument:&attribute atIndex:2];
        [invocation getArgument:&value atIndex:3];

        XCTAssertTrue(value.value);
        XCTAssertTrue([kNRMANoSecureUDIDAttribute isEqualToString:attribute]);

        sessionAttributeAdded = YES;

    }] setNRSessionAttribute:OCMOCK_ANY value:OCMOCK_ANY];


    [[NSNotificationCenter defaultCenter] postNotificationName:kNRMAAnalyticsInitializedNotification
                                                        object:nil
                                                      userInfo:@{kNRMAAnalyticsControllerKey : mockAnalytics}];

    [[NSNotificationCenter defaultCenter] postNotificationName:kNRMASecureUDIDIsNilNotification
                                                        object:nil
                                                      userInfo:nil];

    while (!sessionAttributeAdded && CFRunLoopGetCurrent()) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }


    [mockAnalytics verify];
    [mockAnalytics stopMocking];
    metricGenerator = nil;
}

- (void) testGenerateNoSecureUDIDSecond {
    __block BOOL sessionAttributeAdded = NO;
    NRMAAppInstallMetricGenerator* metricGenerator = [NRMAAppInstallMetricGenerator new];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNRMASecureUDIDIsNilNotification
                                                        object:nil
                                                      userInfo:nil];

    NRMAAnalytics* analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:[NSDate timeIntervalSinceReferenceDate]];

    id mockAnalytics = [OCMockObject partialMockForObject:analytics];


    [[[mockAnalytics expect] andDo:^(NSInvocation *invocation) {
        __autoreleasing NSString* attribute = nil;
        __autoreleasing NRMABool* value = nil;

        [invocation getArgument:&attribute atIndex:2];
        [invocation getArgument:&value atIndex:3];

        XCTAssertTrue(value.value);
        XCTAssertTrue([kNRMANoSecureUDIDAttribute isEqualToString:attribute]);


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
