//
//  NRMAHarvesterTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/29/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRHarvesterTest.h"
#import "NRMAMethodSwizzling.h"
#import <OCMock/OCMock.h>
#import <objc/runtime.h>
#import "NRTestConstants.h"
#import "NRMATraceConfiguration.h"
#import "NewRelicAgent+Development.h"
#import "NRMAHarvestController.h"
#import "NRMAAppToken.h"

@interface NSBundle (AHHHH)
+ (NSBundle*) NRMA__mainBundle;
@end

@interface NRMAHarvester ()
- (NRMAHarvesterConnection*)connection;
- (void)connected;
- (void) disconnected;
- (void) uninitialized;
@end

@implementation NRMAHarvestAwareHelper

- (void) onHarvestStart
{
    self.harvestedStart = YES;
}
- (void) onHarvestStop
{
    self.harvestedStop = YES;
}
- (void) onHarvestBefore
{
    self.harvestedBefore = YES;
}
- (void) onHarvest
{
    self.harvested = YES;
}
- (void) onHarvestError
{
    self.harvestedError = YES;
}
- (void) onHarvestComplete
{
    self.harvestedComplete = YES;
}
@end

@implementation NRMAHarvesterTest

- (void) setUp
{
    [super setUp];
    
    [[NSUserDefaults standardUserDefaults] setObject:@{} forKey:kNRMAHarvesterConfigurationStoreKey];
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:kNRMAApplicationIdentifierKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    agentConfig = [[NRMAAgentConfiguration alloc] initWithAppToken:[[NRMAAppToken alloc] initWithApplicationToken:kNRMA_ENABLED_STAGING_APP_TOKEN]
                                                  collectorAddress:@"staging-mobile-collector.newrelic.com"
                                                      crashAddress:nil];

    harvester = [[NRMAHarvester alloc] init];
    [harvester setAgentConfiguration:agentConfig];

    harvestAwareHelper = [[NRMAHarvestAwareHelper alloc] init];
    [harvester addHarvestAwareObject:harvestAwareHelper];
}

- (void)tearDown
{
    [super tearDown];
}
- (void) testHarvestConfiguration
{
    
    /*
     "collect_network_errors" = 1;
     "cross_process_id" = VQ8HQlVVAQEA;
     "data_report_period" = 60;
     "data_token" =     (
     36920,
     36921
     );
     "error_limit" = 50;
     "report_max_transaction_age" = 600;
     "report_max_transaction_count" = 1000;
     "response_body_limit" = 2048;
     "sever_timestamp" = 1379548800;
     "stack_trace_limit" = 100;
     */
    NRMAHarvesterConfiguration* config = [[NRMAHarvesterConfiguration alloc] init];
    config.application_token = kNRMA_ENABLED_STAGING_APP_TOKEN;
    config.collect_network_errors = YES;
    config.cross_process_id = @"VQ8HQlVVAQWA";
    config.data_report_period = 60;
    config.data_token = [[NRMADataToken alloc] init];
    config.data_token.clusterAgentId = 36920;
    config.data_token.realAgentId = 36921;
    config.error_limit = 50;
    config.report_max_transaction_age = 600;
    config.report_max_transaction_count =1000;
    config.response_body_limit = 2048;
    config.server_timestamp = 1379548800;
    config.stack_trace_limit = 100;
    config.account_id = 340262;
    config.application_id = 257421;
    config.encoding_key = @"d67afc830dab717fd163bfcb0b8b88423e9a1a3b";
    
    XCTAssertTrue([config isEqual:config], @"isEqual is correct");
    XCTAssertTrue([config isEqual:[[NRMAHarvesterConfiguration alloc] initWithDictionary:[config asDictionary]]], @"test asDictionary and initWithDictionary is correct");
}

- (void) testActivityTraceConfiguration
{
    NSArray* at_capture;
    NRMATraceConfigurations *traceConfigurations;

    // Test the most minimal config use case
    /*
    NSString *goodMinimalConfig = @"[1,[]]";
    NSArray* at_capture = [NRMAJSON JSONObjectWithData:[goodMinimalConfig dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];

    NRMATraceConfigurations *traceConfigurations = [[NRMATraceConfigurations alloc] initWithArray:at_capture];
    STAssertNotNil(traceConfigurations, @"Trace configurations is nil");
    STAssertEquals(1, traceConfigurations.maxTotalTraceCount, @"Max trace count should be 1");
    */

    // Test a config which has metric pattern criteria
    NSString *configWithCriterion = @"[1,[[\"/*\",1,[[\"Metric/Pattern\",1,2,3.0,4.0]]]]]";
    at_capture = [NRMAJSON JSONObjectWithData:[configWithCriterion dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    traceConfigurations = [[NRMATraceConfigurations alloc] initWithArray:at_capture];
    XCTAssertNotNil(traceConfigurations, @"Trace configurations is nil");
    XCTAssertEqual(1, traceConfigurations.maxTotalTraceCount, @"Max trace count should be 1");
    XCTAssertNotNil(traceConfigurations.activityTraceConfigurations, @"Activity configuration arrasy is nil");
    XCTAssertEqual(1, (int)traceConfigurations.activityTraceConfigurations.count, @"Should be 1 activity trace configuration");

    NRMATraceConfiguration* configuration = [traceConfigurations.activityTraceConfigurations objectAtIndex:0];
    XCTAssertNotNil(configuration, @"Trace configuration is nil");

    XCTAssertEqualObjects(@"/*", configuration.activityTraceNamePattern, @"Trace name pattern is not correct");

}

- (void) testBadStoredDataRecover
{
    NRMAHarvesterConfiguration* config = [[NRMAHarvesterConfiguration alloc] init];
    config.collect_network_errors = YES;
    config.cross_process_id = @"VQ8HQlVVAQWA";
    config.data_report_period = 60;
    config.data_token = [[NRMADataToken alloc] init];
    config.data_token.clusterAgentId = -1;
    config.data_token.realAgentId = -1;
    config.error_limit = 50;
    config.report_max_transaction_age = 600;
    config.report_max_transaction_count =1000;
    config.response_body_limit = 2048;
    config.server_timestamp = 1379548800;
    config.stack_trace_limit = 100;

    [[NSUserDefaults standardUserDefaults] setObject:[config asDictionary] forKey:kNRMAHarvesterConfigurationStoreKey];
    [[NSUserDefaults standardUserDefaults]synchronize];
    
    NRMAHarvester* newHarvester = [[NRMAHarvester alloc] init];
    id dataMock = [OCMockObject partialMockForObject:[newHarvester harvestData]];
    [[dataMock expect] clear];
    id harvesterMock = [OCMockObject partialMockForObject:newHarvester];
    //[newHarvester setAgentConfiguration:agentConfig];
    [harvesterMock setAgentConfiguration:agentConfig];
    
    //[[harvesterMock expect] andForwardToRealObject]
    [[[harvesterMock expect] andForwardToRealObject] transition:NRMA_HARVEST_DISCONNECTED];

    id connectionMock = [OCMockObject partialMockForObject:[newHarvester connection]];
    [[[connectionMock stub] andForwardToRealObject] sendConnect];
    
    [harvesterMock execute];
    [harvesterMock execute];
    [harvesterMock verify];
    //[connectionMock verify];
    [dataMock verify]; //verify the harvest data is cleared after a successful harvest
    [connectionMock stopMocking];
    [harvesterMock stopMocking];
    [dataMock stopMocking];
//This test fails due to a bug in the collector. (it returns a 500 error instead of a 403/450)
    
}

- (void) testStoredData
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    XCTAssertEqual(harvester.currentState,NRMA_HARVEST_UNINITIALIZED,@"expected uninitialized");
    [harvester execute];
    
    while (CFRunLoopGetCurrent() && harvester.currentState == NRMA_HARVEST_UNINITIALIZED) {};

    XCTAssertEqual(harvester.currentState, NRMA_HARVEST_DISCONNECTED, @"expected disconnected");
    [harvester execute];

    while (CFRunLoopGetCurrent() && harvester.currentState == NRMA_HARVEST_DISCONNECTED) {};
    XCTAssertEqual(harvester.currentState, NRMA_HARVEST_CONNECTED, @"expected connected");

    //at this point there should be stored data
    XCTAssertNotNil([defaults objectForKey:kNRMAHarvesterConfigurationStoreKey], @"this should have been set");
    
    NRMAHarvester* newHarvester = [[NRMAHarvester alloc] init];
    id harvesterMock = [OCMockObject partialMockForObject:newHarvester];
    //[newHarvester setAgentConfiguration:agentConfig];
    [harvesterMock setAgentConfiguration:agentConfig];
    
    [[[harvesterMock expect] andForwardToRealObject] transition:NRMA_HARVEST_DISCONNECTED];
    [[[harvesterMock expect] andForwardToRealObject] transition:NRMA_HARVEST_CONNECTED];

    id connectionMock = [OCMockObject niceMockForClass:[NRMAHarvesterConnection class]];
    [[connectionMock reject] sendConnect];
    
    [harvesterMock execute];
    [harvesterMock execute];
    [harvesterMock verify];
    [connectionMock verify];

    XCTAssertEqual([harvesterMock currentState], NRMA_HARVEST_CONNECTED, @"we should be connected with stored credentials");

    [connectionMock  stopMocking];
    [harvesterMock stopMocking];
}

- (void) testMayUseStoredConfiguration
{
    NRMAHarvesterConfiguration* config = [NRMAHarvesterConfiguration defaultHarvesterConfiguration];
    [harvester saveHarvesterConfiguration:config];
    XCTAssertNotNil([harvester fetchHarvestConfiguration], @"Expected saved configuration to be returned");
}

- (void) testMayUseStoredConfigurationWhenDeviceInfoChanged
{
    NRMAHarvesterConfiguration* config = [NRMAHarvesterConfiguration defaultHarvesterConfiguration];
    [harvester saveHarvesterConfiguration:config];

    // Pretend the app version changed
    [[[self class] fakeInfoDictionary] setObject:@"9000.0" forKey:@"CFBundleShortVersionString"];

    // Cannot use saved configuration because app version has changed
    XCTAssertNil([harvester fetchHarvestConfiguration], @"Expected saved configuration to not be returned");
}

- (void) testDefaultConfigurationIsNotValid
{
    NRMAHarvesterConfiguration* config = [NRMAHarvesterConfiguration defaultHarvesterConfiguration];
    [harvester saveHarvesterConfiguration:config];
    
    XCTAssertFalse([harvester fetchHarvestConfiguration].isValid, @"Expected an invalid default configuration");
}

- (void) testConfigurationWithTokenAndIdsIsValid
{
    NRMAHarvesterConfiguration* config = [NRMAHarvesterConfiguration defaultHarvesterConfiguration];
    config.data_token = [[NRMADataToken alloc] init];
    config.data_token.clusterAgentId = 36920;
    config.data_token.realAgentId = 36921;
    config.application_id = 235225;
    config.account_id = 24523112;
    [harvester saveHarvesterConfiguration:config];
    
    XCTAssertTrue([harvester fetchHarvestConfiguration].isValid, @"Expected a valid default configuration");
}

-(void) testMigrationFromV3toV4ConnectEndpoint {
    
    NRMAHarvester* aHarvester = [[NRMAHarvester alloc] init];
    [aHarvester setAgentConfiguration:agentConfig];
    
    // ensure there is no lingering harvest configuration
    XCTAssertNil([aHarvester fetchHarvestConfiguration]);
    
    [aHarvester execute]; // uninitialized -> disconnected
    [aHarvester execute]; // disconnected -> connected
    
    // we have already connected to v4, so we fake v3 by unsetting the accountID and appID
    NRMAHarvesterConfiguration* currentConfig = [aHarvester fetchHarvestConfiguration];
    currentConfig.account_id = 0;
    currentConfig.application_id = 0;
    
    // ensure we are connected via expected v3 configuration
    [aHarvester saveHarvesterConfiguration:currentConfig];
    XCTAssertEqual(aHarvester.currentState, NRMA_HARVEST_CONNECTED);
    XCTAssertFalse([[aHarvester fetchHarvestConfiguration] isValid]);
    XCTAssertEqual(0, [aHarvester fetchHarvestConfiguration].account_id);
    XCTAssertEqual(0, [aHarvester fetchHarvestConfiguration].application_id);
    
    [aHarvester execute]; // connected -> connected -- should force a reconnect via v4
    XCTAssertEqual(aHarvester.currentState, NRMA_HARVEST_CONNECTED);
    XCTAssertTrue([[aHarvester fetchHarvestConfiguration] isValid]);
    XCTAssertEqual(190, [aHarvester fetchHarvestConfiguration].account_id);
    XCTAssertEqual(39484, [aHarvester fetchHarvestConfiguration].application_id);
    
    aHarvester = nil;
}

- (void) testUninitializedtoConnected
{

   
//    NSString* appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
//    NSString* appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
//    NSString* bundleID = [[NSBundle mainBundle] bundle ];
    
    XCTAssertEqual(harvester.currentState,NRMA_HARVEST_UNINITIALIZED,@"expected uninitialized");
    
    //uninitialized -> disconnected
    [harvester execute];

    while (CFRunLoopGetCurrent() && harvester.currentState == NRMA_HARVEST_UNINITIALIZED) {};
    XCTAssertEqual(harvester.currentState, NRMA_HARVEST_DISCONNECTED, @"expected disconnected");
    
    //Disconnected -> connected
    [harvester execute];

    while (CFRunLoopGetCurrent() && harvester.currentState == NRMA_HARVEST_DISCONNECTED) {};
    XCTAssertEqual(harvester.currentState, NRMA_HARVEST_CONNECTED, @"expected connected");
}

//- (void) testUninitializedToDisabled
//{
//
//    agentConfig = [[NRMAAgentConfiguration alloc] initWithAppToken:[[NRMAAppToken alloc] initWithApplicationToken:@"AA06d1964231f6c881cedeaa44e837bde4079c683d"]
//                                                  collectorAddress:nil
//                                                      crashAddress:nil];
//
//    [harvester setAgentConfiguration:agentConfig];
//
//    XCTAssertEqual(harvester.currentState, NRMA_HARVEST_UNINITIALIZED, @"expected uninitizlized");
//    [harvester execute];
//
//
//    while (CFRunLoopGetCurrent() && harvester.currentState == NRMA_HARVEST_UNINITIALIZED) {};
//    XCTAssertEqual(harvester.currentState, NRMA_HARVEST_DISCONNECTED, @"expected disconnected");
//
//    [harvester execute];
//
//    while (CFRunLoopGetCurrent() && harvester.currentState == NRMA_HARVEST_DISCONNECTED) {};
//    XCTAssertEqual(harvester.currentState, NRMA_HARVEST_DISABLED, @"expected disabled");
//}

- (void) testAppVersionUsesCFBundleShortVersionString
{
    NSString *realBundleVersion = [[[self class] fakeInfoDictionary] objectForKey:@"CFBundleShortVersionString"];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [NewRelic setApplicationVersion:nil];
#pragma clang diagnsotic pop
    NRMAConnectInformation *info = [NRMAAgentConfiguration connectionInformation];

    XCTAssertEqual(info.applicationInformation.appVersion, realBundleVersion,
                   @"appInfo.appVersion should equal '%@' but is '%@'",
                   realBundleVersion, info.applicationInformation.appVersion);
}

- (void) testAppVersionUsesOverride
{
    NSString *overrideVersion = @"9.5.4.1";

    [NewRelic setApplicationVersion:overrideVersion];
    NRMAConnectInformation *info = [NRMAAgentConfiguration connectionInformation];

    XCTAssertEqual(info.applicationInformation.appVersion, overrideVersion,
                   @"appInfo.appVersion should equal '%@' but is '%@'",
                   overrideVersion, info.applicationInformation.appVersion);

    [NewRelic setApplicationVersion:@""];
}

- (void) testAppVersionClearsOverride
{
    NSString *realBundleVersion = [[[self class] fakeInfoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *overrideVersion = @"9.5.4.1";

    [NewRelic setApplicationVersion:overrideVersion];
    NRMAConnectInformation *info = [NRMAAgentConfiguration connectionInformation];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [NewRelic setApplicationVersion:nil];
#pragma clang diagnostic pop
    info = [NRMAAgentConfiguration connectionInformation];

    XCTAssertEqual(info.applicationInformation.appVersion, realBundleVersion,
                   @"appInfo.appVersion should equal '%@' but is '%@'",
                   realBundleVersion, info.applicationInformation.appVersion);
    [NewRelic setApplicationVersion:@""];
}

- (void) testBuildVersionUsesCFBundleVersion
{
    NSString *realBundleVersion = [[[self class] fakeInfoDictionary] objectForKey:@"CFBundleVersion"];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [NewRelic setApplicationVersion:nil];
#pragma clang diagnostic pop
    NRMAConnectInformation *info = [NRMAAgentConfiguration connectionInformation];

    XCTAssertEqual(info.applicationInformation.appBuild, realBundleVersion,
                   @"appInfo.appBuild should equal '%@' but is '%@'",
                   realBundleVersion, info.applicationInformation.appVersion);
}

- (void) testBuildVersionUsesOverride
{
    NSString *overrideBuild = @"9541";

    [NewRelic setApplicationBuild:overrideBuild];
    NRMAConnectInformation *info = [NRMAAgentConfiguration connectionInformation];

    XCTAssertEqual(info.applicationInformation.appBuild, overrideBuild,
                   @"appInfo.appBuild should equal '%@' but is '%@'",
                   overrideBuild, info.applicationInformation.appBuild);

    [NewRelic setApplicationVersion:@""];
}

- (void) testBuildVersionClearsOverride
{
    NSString *realBundleVersion = [[[self class] fakeInfoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *overrideVersion = @"9541";

    [NewRelic setApplicationBuild:overrideVersion];
    NRMAConnectInformation *info = [NRMAAgentConfiguration connectionInformation];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [NewRelic setApplicationBuild:nil];
#pragma clang diagnostic pop
    info = [NRMAAgentConfiguration connectionInformation];

    XCTAssertEqual(info.applicationInformation.appBuild, realBundleVersion,
                   @"appInfo.appBuild should equal '%@' but is '%@'",
                   realBundleVersion, info.applicationInformation.appBuild);
    [NewRelic setApplicationBuild:@""];
}


- (void) testDisconnectedThrowsException
{
    id mockHarvester = [OCMockObject partialMockForObject:harvester];
    [[[mockHarvester stub] andReturn:nil] harvestData];
    [harvester uninitialized];
    XCTAssertNoThrow([harvester disconnected],@"");
    [mockHarvester stopMocking];
}

- (void) testConnectedThrowException
{
    id mockHarvester = [OCMockObject partialMockForObject:harvester];
    id mockConnection = [OCMockObject partialMockForObject:[mockHarvester connection]];
    [[[mockHarvester stub] andReturn:[NRMAHarvesterConfiguration new]] harvesterConfiguration];

    [[[mockConnection stub] andDo:^(NSInvocation *invocation) {
        @throw [NSException exceptionWithName:@"" reason:@"" userInfo:nil];
    }] sendData:OCMOCK_ANY];

     XCTAssertNoThrow([mockHarvester connected],@"assert we don't crash if something goes wrong in connected");

    [mockHarvester stopMocking];
    [mockConnection stopMocking];
}

- (void) testBadTokenResponsesDontCrashApp {
    id mockHarvester = [OCMockObject partialMockForObject:harvester];
    id mockConnection = [OCMockObject partialMockForObject:[mockHarvester connection]];
    [[[mockHarvester stub] andReturn:[NRMAHarvesterConfiguration new]] harvesterConfiguration];
    
    [[[mockConnection stub] andDo:^(NSInvocation *invocation) {
        @throw [NSException exceptionWithName:@"" reason:@"" userInfo:nil];
    }] sendConnect];
    
    NRMAHarvestResponse* request = [[NRMAHarvestResponse alloc] init];
    request.statusCode = INVALID_AGENT_ID;
    
    [[[mockConnection stub] andReturn:request] sendData:OCMOCK_ANY];

    XCTAssertNoThrow([mockHarvester connected],@"assert we don't crash if something goes wrong in connected");
    
    [mockHarvester stopMocking];
    [mockConnection stopMocking];
}

- (void) testConectedv3AppsDontCrashApp {
    id mockHarvester = [OCMockObject partialMockForObject:harvester];
    id mockConnection = [OCMockObject partialMockForObject:[mockHarvester connection]];
    NRMAHarvesterConfiguration* v3config = [[NRMAHarvesterConfiguration alloc] init];
    v3config.collect_network_errors = YES;
    v3config.cross_process_id = @"VQ8HQlVVAQWA";
    v3config.data_report_period = 60;
    v3config.data_token = [[NRMADataToken alloc] init];
    v3config.data_token.clusterAgentId = 36920;
    v3config.data_token.realAgentId = 36921;
    v3config.error_limit = 50;
    v3config.report_max_transaction_age = 600;
    v3config.report_max_transaction_count =1000;
    v3config.response_body_limit = 2048;
    v3config.server_timestamp = 1379548800;
    v3config.stack_trace_limit = 100;
    v3config.account_id = 0;
    v3config.application_id = 0;
    v3config.encoding_key = @"d67afc830dab717fd163bfcb0b8b88423e9a1a3b";
    [[[mockHarvester stub] andReturn:v3config] fetchHarvestConfiguration];
    
    [[[mockConnection stub] andDo:^(NSInvocation *invocation) {
        @throw [NSException exceptionWithName:@"" reason:@"" userInfo:nil];
    }] sendData:OCMOCK_ANY];
    
    XCTAssertNoThrow([mockHarvester connected],@"assert we don't crash if something goes wrong in connected");
    
    [mockHarvester stopMocking];
    [mockConnection stopMocking];
}


@end
