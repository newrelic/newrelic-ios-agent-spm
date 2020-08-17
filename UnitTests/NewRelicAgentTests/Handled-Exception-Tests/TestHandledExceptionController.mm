//
//  TestHandledExceptionController.m
//  NewRelic
//
//  Created by Bryce Buchanan on 6/28/17.
//  Copyright (c) 2017 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMABool.h"
#import "NRMAHandledExceptions.h"
#import "NRMAExceptionReportAdaptor.h"
#import "NRMAAgentConfiguration.h"

#import "NewRelicInternalUtils.h"

#import <Hex/HexContext.hpp>
#import "NRAgentTestBase.h"
#import "NRLogger.h"
#import "NRMAAppToken.h"
#import <OCMock/OCMock.h>
@interface TestHandledExceptionController : NRMAAgentTestBase {
    unsigned long long epoch_time_ms;
    const char* sessionDataPath;
}

@end


@interface NRMAExceptionReportAdaptor()
- (void) addKey:(NSString*)key
    stringValue:(NSString*)string;

- (void) addKey:(NSString*)key
      boolValue:(NRMABool*)boolean;

- (void) addKey:(NSString*)key
    numberValue:(NSNumber*)num;
@end

@interface NRMAHandledExceptions ()
- (fbs::Platform) fbsPlatformFromString:(NSString*)platform;
@end

@implementation TestHandledExceptionController

- (void) setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void) tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void) testBadParams {
    [NRLogger setLogLevels:NRLogLevelALL];
    XCTAssertNoThrow([[NRMAHandledExceptions alloc] initWithAnalyticsController:nil
                                                               sessionStartTime:0
                                                             agentConfiguration:nil
                                                                       platform:nil
                                                                      sessionId:nil]);

    NRMAAnalytics* analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:0];
    NRMAHandledExceptions* exceptions = [[NRMAHandledExceptions alloc] initWithAnalyticsController:nil
                                                                                  sessionStartTime:0
                                                                                agentConfiguration:nil
                                                                                          platform:nil
                                                                                         sessionId:nil];


    XCTAssertTrue(exceptions == nil);

    XCTAssertNoThrow([exceptions recordHandledException:[NSException exceptionWithName:@"Hot Tea Exception" reason:@"the Tea is too hot" userInfo:@{}]]);

    exceptions = [[NRMAHandledExceptions alloc] initWithAnalyticsController:analytics
                                                           sessionStartTime:0
                                                         agentConfiguration:nil
                                                                   platform:nil
                                                                  sessionId:nil];

    XCTAssertTrue(exceptions == nil);

    XCTAssertNoThrow([exceptions recordHandledException:[NSException exceptionWithName:@"Hot Tea Exception" reason:@"the Tea is too hot" userInfo:@{}]]);

    NRMAAgentConfiguration* agentConfig = [[NRMAAgentConfiguration alloc] initWithAppToken:[[NRMAAppToken alloc] initWithApplicationToken:@"12345"]
                                                                          collectorAddress:nil
                                                                              crashAddress:nil];
    exceptions = [[NRMAHandledExceptions alloc] initWithAnalyticsController:analytics
                                                           sessionStartTime:0
                                                         agentConfiguration:agentConfig
                                                                   platform:nil
                                                                  sessionId:nil];

    XCTAssertTrue(exceptions == nil);

    XCTAssertNoThrow([exceptions recordHandledException:[NSException exceptionWithName:@"Hot Tea Exception" reason:@"the Tea is too hot" userInfo:@{}]]);

    exceptions = [[NRMAHandledExceptions alloc] initWithAnalyticsController:analytics
                                                           sessionStartTime:0
                                                         agentConfiguration:agentConfig
                                                                   platform:@"iOS"
                                                                  sessionId:nil];

    XCTAssertTrue(exceptions == nil);

    XCTAssertNoThrow([exceptions recordHandledException:[NSException exceptionWithName:@"Hot Tea Exception" reason:@"the Tea is too hot" userInfo:@{}]]);
}

- (void) testHandleException {
    NRMAAnalytics* analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:0];
    NRMAAgentConfiguration* agentConfig = [[NRMAAgentConfiguration alloc] initWithAppToken:[[NRMAAppToken alloc] initWithApplicationToken:@"blah"]
                                                                          collectorAddress:nil
                                                                              crashAddress:nil];
    agentConfig.sessionIdentifier = @"1234-567-890";

    NRMAHandledExceptions* hexController = [[NRMAHandledExceptions alloc] initWithAnalyticsController:analytics
                                                                                     sessionStartTime:0
                                                                                   agentConfiguration:agentConfig
                                                                                             platform:[NewRelicInternalUtils osName]
                                                                                            sessionId:@"sessionId"];

    XCTAssertNoThrow([hexController recordHandledException:[NSException exceptionWithName:@"Hot Tea Exception"
                                                                                   reason:@"the Tea is too hot"
                                                                                 userInfo:@{}]]);

    XCTAssertNoThrow([hexController recordHandledException:nil]);

    NSDictionary* dict = @{@"string":@"string",
            @"num":@1};
    XCTAssertNoThrow([hexController recordHandledException:[NSException exceptionWithName:@"Hot Tea Exception"
                                                                                   reason:@"the tea is too hot"
                                                                                 userInfo:nil]
                                                attributes:dict]);

    XCTAssertNoThrow([hexController recordHandledException:nil
                                                attributes:dict]);
}


- (void) testPlatform {
    NRMAAnalytics* analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:0];
    NRMAAgentConfiguration* agentConfig = [[NRMAAgentConfiguration alloc] initWithAppToken:[[NRMAAppToken alloc] initWithApplicationToken:@"blah"]
                                                                          collectorAddress:nil
                                                                              crashAddress:nil];
    agentConfig.sessionIdentifier = @"1234-567-890";

    NRMAHandledExceptions* hexController = [[NRMAHandledExceptions alloc] initWithAnalyticsController:analytics
                                                                                     sessionStartTime:[NSDate new]
                                                                                   agentConfiguration:agentConfig
                                                                                             platform:[NewRelicInternalUtils osName]
                                                                                            sessionId:@"sessionId"];
    XCTAssertTrue([hexController fbsPlatformFromString:@"iOS"] == com::newrelic::mobile::fbs::Platform_iOS, @"Method returned %d, but should be %d", [hexController fbsPlatformFromString:@"iOS"],com::newrelic::mobile::fbs::Platform_iOS );
    XCTAssertTrue([hexController fbsPlatformFromString:@"tvOS"] == com::newrelic::mobile::fbs::Platform_tvOS,@"Method returned %d, but should be %d", [hexController fbsPlatformFromString:@"tvOS"],com::newrelic::mobile::fbs::Platform_tvOS);

}

- (void) testDontRecordUnThrownExceptions {
    NRMAAnalytics* analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:0];
    NRMAAgentConfiguration* agentConfig = [[NRMAAgentConfiguration alloc] initWithAppToken:[[NRMAAppToken alloc] initWithApplicationToken:@"blah"]
                                                                          collectorAddress:nil
                                                                              crashAddress:nil];
    agentConfig.sessionIdentifier = @"1234-567-890";
    agentConfig.platform = NRMAPlatform_Native;

    NRMAHandledExceptions* hexController = [[NRMAHandledExceptions alloc] initWithAnalyticsController:analytics
                                                                                     sessionStartTime:[NSDate new]
                                                                                   agentConfiguration:agentConfig
                                                                                             platform:[NewRelicInternalUtils osName]
                                                                                            sessionId:@"sessionId"];
    
    id mockLogger = [OCMockObject mockForClass:[NRLogger class]];
    
    
    [[[[mockLogger expect] ignoringNonObjectArgs] classMethod]  log:0
                                                            inFile:OCMOCK_ANY
                                                            atLine:0
                                                          inMethod:OCMOCK_ANY
                                                        withMessage:[OCMArg checkWithBlock:^BOOL(NSString* obj) {
        return [obj containsString:@"Invalid exception."];
    }]];

    
    XCTAssertNoThrow([hexController recordHandledException:[NSException exceptionWithName:@"Hot Tea Exception"
                                                                                   reason:@"the Tea is too hot"
                                                                                 userInfo:@{}]]);
    
    XCTAssertNoThrow([mockLogger verify]);
    
    [mockLogger stopMocking];
    
}
@end
