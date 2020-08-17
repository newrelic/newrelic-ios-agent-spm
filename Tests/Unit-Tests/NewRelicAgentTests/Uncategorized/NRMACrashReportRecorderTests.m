//
//  NRMACrashReportRecorderTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/12/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMACrashReporterRecorder.h"
#import "NRMAMeasurements.h"
#import <OCMock/OCMock.h>

@interface NRMACrashReporterRecorder ()
- (void) generateTestFlightMetrics;
- (void) generateCrashlyticsMetrics;
- (void) generateCrittercismMetrics;
- (void) generateFlurryMetrics;
- (void) generateHockeyMetrics;

- (BOOL) isFlurryDefined;
- (BOOL) isHockeyDefined;
- (BOOL) isCrittercismDefined;
- (BOOL) isCrashlyticsDefined;
- (BOOL) isTestFlightDefined;
@end

@interface NRMACrashReportRecorderTests : XCTestCase
{
    id mockRecorder;
    id mockMeasurements;
    NRMACrashReporterRecorder* recorder;
}
@end

@implementation NRMACrashReportRecorderTests

- (void)setUp
{
    [super setUp];
    recorder = [[NRMACrashReporterRecorder alloc] init];
    mockRecorder = [OCMockObject partialMockForObject:recorder];
    mockMeasurements = [OCMockObject mockForClass:[NRMAMeasurements class]];
}

- (void)tearDown
{
    [mockRecorder stopMocking];
    [mockMeasurements stopMocking];
    [super tearDown];
}

- (void) testValidTestFlightMeasurements
{
    BOOL retValue = YES;
    [[[[mockMeasurements expect] andDo:^(NSInvocation *invocation) {
        __autoreleasing NSString* metricName = nil;
        [invocation getArgument:&metricName atIndex:2];
        NSString* expectedString = [NSString stringWithFormat:@"%@/%@/%@",kNRAgentHealthPrefix,kNRMAUncaughtExceptionTag,kNRMAExceptionHandler_TestFlight];
        XCTAssertTrue([metricName isEqualToString:expectedString],@"%@, doesn't match expected string: %@",metricName,expectedString);
    }] classMethod] recordAndScopeMetricNamed:OCMOCK_ANY value:OCMOCK_ANY];


    [[[mockRecorder expect] andReturnValue:[NSValue valueWithBytes:&retValue objCType:@encode(BOOL)]] isTestFlightDefined];

    [mockRecorder generateTestFlightMetrics];

    XCTAssertNoThrow([mockMeasurements verify],@"");
    XCTAssertNoThrow([mockRecorder verify], @"");
}

- (void) testValidFlurryMeasurements
{
    BOOL retValue = YES;
    [[[[mockMeasurements expect] andDo:^(NSInvocation *invocation) {
        __autoreleasing NSString* metricName = nil;
        [invocation getArgument:&metricName atIndex:2];
        NSString* expectedString = [NSString stringWithFormat:@"%@/%@/%@",kNRAgentHealthPrefix,kNRMAUncaughtExceptionTag,kNRMAExceptionHandler_Flurry];
        XCTAssertTrue([metricName isEqualToString:expectedString],@"%@, doesn't match expected string: %@",metricName,expectedString);
    }] classMethod] recordAndScopeMetricNamed:OCMOCK_ANY value:OCMOCK_ANY];


    [[[mockRecorder expect] andReturnValue:[NSValue valueWithBytes:&retValue objCType:@encode(BOOL)]] isFlurryDefined];

    [mockRecorder generateFlurryMetrics];

    XCTAssertNoThrow([mockMeasurements verify],@"");
    XCTAssertNoThrow([mockRecorder verify], @"");
}

- (void) testValidCrashlyticsMeasurements
{
    BOOL retValue = YES;
    [[[[mockMeasurements expect] andDo:^(NSInvocation *invocation) {
        __autoreleasing NSString* metricName = nil;
        [invocation getArgument:&metricName atIndex:2];
        NSString* expectedString = [NSString stringWithFormat:@"%@/%@/%@",kNRAgentHealthPrefix,kNRMAUncaughtExceptionTag,kNRMAExceptionHandler_Crashlytics];
        XCTAssertTrue([metricName isEqualToString:expectedString],@"%@, doesn't match expected string: %@",metricName,expectedString);
    }] classMethod] recordAndScopeMetricNamed:OCMOCK_ANY value:OCMOCK_ANY];


    [[[mockRecorder expect] andReturnValue:[NSValue valueWithBytes:&retValue objCType:@encode(BOOL)]] isCrashlyticsDefined];

    [mockRecorder generateCrashlyticsMetrics];

    XCTAssertNoThrow([mockMeasurements verify],@"");
    XCTAssertNoThrow([mockRecorder verify], @"");
}

- (void) testValidCrittercismMeasurements
{
    BOOL retValue = YES;
    [[[[mockMeasurements expect] andDo:^(NSInvocation *invocation) {
        __autoreleasing NSString* metricName = nil;
        [invocation getArgument:&metricName atIndex:2];
        NSString* expectedString = [NSString stringWithFormat:@"%@/%@/%@",kNRAgentHealthPrefix,kNRMAUncaughtExceptionTag,kNRMAExceptionHandler_Crittercism];
        XCTAssertTrue([metricName isEqualToString:expectedString],@"%@, doesn't match expected string: %@",metricName,expectedString);
    }] classMethod] recordAndScopeMetricNamed:OCMOCK_ANY value:OCMOCK_ANY];


    [[[mockRecorder expect] andReturnValue:[NSValue valueWithBytes:&retValue objCType:@encode(BOOL)]] isCrittercismDefined];

    [mockRecorder generateCrittercismMetrics];

    XCTAssertNoThrow([mockMeasurements verify],@"");
    XCTAssertNoThrow([mockRecorder verify], @"");
}

- (void) testValidHockeyMeasurements
{
    BOOL retValue = YES;
    [[[[mockMeasurements expect] andDo:^(NSInvocation *invocation) {
        __autoreleasing NSString* metricName = nil;
        [invocation getArgument:&metricName atIndex:2];
        NSString* expectedString = [NSString stringWithFormat:@"%@/%@/%@",kNRAgentHealthPrefix,kNRMAUncaughtExceptionTag,kNRMAExceptionHandler_Hockey];
        XCTAssertTrue([metricName isEqualToString:expectedString],@"%@, doesn't match expected string: %@",metricName,expectedString);
    }] classMethod] recordAndScopeMetricNamed:OCMOCK_ANY value:OCMOCK_ANY];


    [[[mockRecorder expect] andReturnValue:[NSValue valueWithBytes:&retValue objCType:@encode(BOOL)]] isHockeyDefined];

    [mockRecorder generateHockeyMetrics];

    XCTAssertNoThrow([mockMeasurements verify],@"");
    XCTAssertNoThrow([mockRecorder verify], @"");
}


@end
