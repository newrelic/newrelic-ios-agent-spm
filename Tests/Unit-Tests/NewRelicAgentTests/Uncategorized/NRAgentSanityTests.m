////
////  NRMAAgentSanityTests.m
////  NewRelicAgent
////
////  Created by Jonathan Karon on 10/2/12.
////  Copyright (c) 2012 New Relic. All rights reserved.
////
//
//#import "NRAgentSanityTests.h"
//#import "NRJSON.h"
//#import "NRTestConstants.h"
//#import "NRHarvestController.h"
//#import "NRNSURLConnectionSupport.h"
//#import "NRHarvestableMetric.h"
//
//extern NSString *_NRMAAgentApplicationName;
//extern NSString *_NRMAAgentApplicationVersion;
//extern NSString *_NRMAAgentApplicationBundleId;
//extern NetworkStatus ReachableViaWWANMethod();
//extern NetworkStatus NotReachableMethod();
//
//
//
//@implementation NRMAAgentSanityTests 
//
//- (void) setUp
//{
////    [super setUp];
////        [NewRelicAgent startWithApplicationToken:kNRMA_ENABLED_STAGING_APP_TOKEN
////                             andCollectorAddress:KNRMA_TEST_COLLECTOR_HOST
////                                         withSSL:NO];
////    while (CFRunLoopGetMain() && [[NRMAHarvestController harvestController] harvester].currentState != NRMA_HARVEST_CONNECTED){};
//
//}
//
//- (void)tearDown
//{
//    [NRMAHarvestController stop];
//    [NRMANSURLConnectionSupport deinstrumentNSURLConnection];
//    [super tearDown];
//}
//- (void)testAgentStarted
//{
////    STAssertNotNil([NewRelicAgentInternal sharedInstance], @"Agent instance was nil");
//}
//
//bool shouldHaveSessionDurationMetric;
//
//- (void)testAgentReportsSessionDurationOnBackground
//{
//    [[NRMAHarvestController harvestController] addHarvestAwareObject:self];
//    
//    shouldHaveSessionDurationMetric = YES;
//    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:[UIApplication sharedApplication]];
//}
//
//- (void)testAgentDoesNotReportSessionDurationOnForegroundHarvests
//{
//    [[NRMAHarvestController harvestController] addHarvestAwareObject:self];
//    
//    shouldHaveSessionDurationMetric = NO;
//    
//    // Just give it something to harvest.
//    [NRMAMeasurements recordNamedValue:@"Some/Metric" value:@1 withScope:nil];
//    [[[NRMAHarvestController harvestController] harvester] execute];
//}
//
//// If future tests need to use the harvest aware callbacks, this needs to be split up somehow. Currently only for testAgentReportsSessionDurationOnBackground and testAgentDoesNotReportSessionDurationOnForegroundHarvests
//- (void) onHarvestBefore {
//    NSDictionary *metrics = [[NRMAHarvestController harvestData].metrics flushMetrics];
//    NRMAHarvestableMetric *metric = [metrics valueForKey:@"Session/Duration"];
//    
//    if (shouldHaveSessionDurationMetric) {
//        STAssertNotNil(metric, @"No Session/Duration metric found");
//        NSDictionary *allValues = [metric allValues][0];
//        NSNumber *value = [allValues valueForKey:@"value"];
//        STAssertTrue([value doubleValue] > 0.0, @"No Session/Duration value");
//    } else {
//        STAssertNil(metric, @"Session/Duration metric should not be present.");
//    }
//}
//
//- (void)testAgentRestoresState
//{
//    //TODO: UPDATE!
////    // be sure we have completed our server negotiation
////    STAssertNotNil([[NewRelicAgentInternal sharedInstance] connectSync], @"Agent failed connectSync");
////    
////    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
////    id dataToken = [defs objectForKey:NEWRELIC_DATA_TOKEN_SETTINGS_KEY];
////    NSString *cpid = [defs objectForKey:NEWRELIC_CROSS_PROCESS_ID_SETTINGS_KEY];
////    STAssertNotNil(dataToken, @"settings should have a data token");
////    STAssertTrue(cpid.length > 0, @"settings hsould have a cross-process id");
////    
////    [[NewRelicAgentInternal sharedInstance] destroyAgent];
////    
////    [NewRelicAgent startWithApplicationToken:TEST_APPLICATION_TOKEN andCollectorAddress:TEST_COLLECTOR_HOST withSSL:NO];
////    
////    NewRelicAgentInternal* agent = [NewRelicAgentInternal sharedInstance];
////    STAssertTrue([agent restoreState], @"Agent failed to restore state from settings");
////    STAssertTrue(agent.crossProcessId.length > 0, @"Agent does not have a cross process id");
////    STAssertTrue([agent isConnected], @"Agent does not have a data token");
////
////    [agent clearServerState];
////    STAssertFalse(agent.crossProcessId.length > 0, @"Agent has a cross process id");
////    STAssertFalse([agent isConnected], @"Agent has a data token");
//
//    
//}
//
////- (void)testAgentEnablesSSLInCollectorAddress
////{
////    NewRelicAgentInternal* agent = [NewRelicAgentInternal sharedInstance];
////    [agent clearState];
////    [[NewRelicAgentInternal sharedInstance] destroyAgent];
////
////    [NewRelicAgent startWithApplicationToken:TEST_APPLICATION_TOKEN andCollectorAddress:TEST_COLLECTOR_HOST withSSL:YES];
////
////    agent = [NewRelicAgentInternal sharedInstance];
////
////    NSString *address = agent.collectorAddress;
////    STAssertTrue([address hasPrefix:@"https:"], @"agent should be using https but is not");
////}
////- (void)testAgentDisablesSSLInCollectorAddress
////{
////    NewRelicAgentInternal* agent = [NewRelicAgentInternal sharedInstance];
////    [agent clearState];
////    [[NewRelicAgentInternal sharedInstance] destroyAgent];
////
////    [NewRelicAgent startWithApplicationToken:TEST_APPLICATION_TOKEN andCollectorAddress:TEST_COLLECTOR_HOST withSSL:NO];
////
////    agent = [NewRelicAgentInternal sharedInstance];
////
////    NSString *address = agent.collectorAddress;
////    STAssertTrue([address hasPrefix:@"http:"], @"agent should NOT be using https but is");
////}
////
//
////- (void)testAppInfo
////{
////    NewRelicAgentInternal* agent = [NewRelicAgentInternal sharedInstance];
////    STAssertNotNil([agent applicationInfo], @"applicationInfo should return an array");
////    STAssertEquals((int)[agent applicationInfo].count, 3, @"applicationInfo should be a 3-element array");
////}
//
////- (void)testAgentShutdown
////{
////    NewRelicAgentInternal* agent = [NewRelicAgentInternal sharedInstance];
////    // test that this doesn't blow up or anything
////    STAssertTrue([agent shutdown], @"Shutdown failed");
////    STAssertFalse([agent shutdown], @"Shutdown should have returned false");
////}
//
//- (void)testAgentIsEnabled
//{
//    NewRelicAgentInternal* agent = [NewRelicAgentInternal sharedInstance];
//    // test that this doesn't blow up or anything
//    STAssertTrue(agent.enabled, @"Agent is not enabled");
//}
//
////- (void)testAgentDisable
////{
////    NewRelicAgentInternal* agent = [NewRelicAgentInternal sharedInstance];
////
////    STAssertFalse(agent.isDisabled, @"Agent incorrectly reports disabled");
////    
//////    [agent permanentlyDisable];
////    STAssertTrue([agent isDisabled], @"Agent incorrectly reports enabled");
////    
////    //[NewRelicAgentInternal revokePermanentDisable];
////    //STAssertFalse(agent.isDisabled, @"Agent incorrectly reports disabled");
////}
////
////- (void)testAgentDisabledOnStart
////{
////    NewRelicAgentInternal* agent = [NewRelicAgentInternal sharedInstance];
////    STAssertTrue(agent.enabled, @"Agent incorrectly reports disabled");
////    
//////    [agent permanentlyDisable];
////    STAssertTrue([agent isDisabled], @"Agent incorrectly reports enabled");
////    
////    [agent destroyAgent];
////
////    [NewRelicAgent startWithApplicationToken:TEST_APPLICATION_TOKEN andCollectorAddress:TEST_COLLECTOR_HOST withSSL:NO];
////
////    agent = [NewRelicAgentInternal sharedInstance];
////    STAssertFalse(agent.enabled, @"Agent is not disabled on start");
////
////    //[NewRelicAgentInternal revokePermanentDisable];
////
////    [agent destroyAgent];
////    
////    [NewRelicAgent startWithApplicationToken:TEST_APPLICATION_TOKEN andCollectorAddress:TEST_COLLECTOR_HOST withSSL:NO];
////    
////    agent = [NewRelicAgentInternal sharedInstance];
////    STAssertTrue(agent.enabled, @"Agent incorrectly reports disabled");
////}
//
////- (void)testAgentObeysSSLFlag
////{
////    [[NewRelicAgentInternal sharedInstance] destroyAgent];
////
////    // check that we can instantiate an agent with HTTPS support
////    [NewRelicAgent startWithApplicationToken:TEST_APPLICATION_TOKEN andCollectorAddress:TEST_COLLECTOR_HOST withSSL:YES];
////    
////    STAssertTrue([[[NewRelicAgentInternal sharedInstance] getFullCollectorAddress:TEST_COLLECTOR_HOST] hasPrefix:@"https://"], @"test agent should be using https://");
////
////    [[NewRelicAgentInternal sharedInstance] destroyAgent];
////
////    // and check that we can instantiate an agent without HTTPS support
////    [NewRelicAgent startWithApplicationToken:TEST_APPLICATION_TOKEN andCollectorAddress:TEST_COLLECTOR_HOST withSSL:NO];
////
////    STAssertTrue([[[NewRelicAgentInternal sharedInstance] getFullCollectorAddress:TEST_COLLECTOR_HOST] hasPrefix:@"http://"], @"test agent should be using http://");
////}
//
////this is handled else where
////- (void)testAgentIdentityString
////{
////    NSString *str = [[NewRelicAgentInternal sharedInstance] applicationDeviceIdentityAsString];
////    NSError *err = nil;
////    NSArray *data = [NRMAJSON JSONObjectWithData:[str dataUsingEncoding:NSASCIIStringEncoding]
////                                              options:0
////                                                error:&err];
////    STAssertNil(err, @"error decoding applicationDeviceIdentityAsString: %@", err.description);
////    STAssertNotNil(data, @"no data decoded from applicationDeviceIdentityAsString");
////    STAssertTrue([data respondsToSelector:@selector(count)], @"applicationDeviceIdentityAsString did not return an array: %@", data);
////    STAssertEquals((int)data.count, 2, @"expected 2 items in app identity, not %d", data.count);
////}
//
////- (void)testAgentHasCrossProcessId
////{
////    NewRelicAgentInternal* agent = [NewRelicAgentInternal sharedInstance];
////    // test that this doesn't blow up or anything
////    STAssertNotNil(agent.crossProcessId, @"Agent has nil CrossProcessId");
////    STAssertFalse(0 == agent.crossProcessId.length, @"Agent has blank CrossProcessId");
////}
//
//
//-(void)testDeviceModel
//{
//    NSString *model = [NewRelicInternalUtils deviceModel];
//    STAssertTrue([model isEqualToString:@"x86_64"], @"deviceModel is '%@' but should be 'x86_64'", model);
//}
//
//
//-(void)testCarrierName
//{
//    NSString* carrier = [NewRelicInternalUtils carrierName];
//    STAssertTrue([carrier isEqualToString:@"wifi"], @"Carrier :%@", carrier);
//}
//
//-(void)testCarrierNameReachableViaWWAN
//{
//    void* origMethod = NRMAReplaceInstanceMethod([NRMAReachability class], @selector(currentReachabilityStatus), (IMP)ReachableViaWWANMethod);
//    @try {
//        NSString* carrier = [NewRelicInternalUtils carrierName];
//        STAssertTrue([carrier isEqualToString:@"Other"], @"Carrier should be Other");
//    } @finally {
//        NRMAReplaceInstanceMethod([NRMAReachability class], @selector(currentReachabilityStatus), origMethod);
//    }
//}
//
//
///*
// -(void)testPermanentlyDisable
// {
// NewRelicAgentInternal* agent = [[NewRelicAgentInternal alloc] init];
// STAssertTrue(agent.enabled, @"Agent disabled");
// [agent permanentlyDisable];
// 
// agent = [[NewRelicAgentInternal alloc] init];
// STAssertFalse(agent.enabled, @"Agent enabled");
// }
// 
// -(void)testPermanentlyDisableOlderVersion
// {
// NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
// // set the disabled version to an old version
// [defaults setObject:[NSNumber numberWithDouble:0.1] forKey:@"NewRelicAgentDisabledVersion"];
// [defaults synchronize];
// 
// NewRelicAgentInternal* agent = [[NewRelicAgentInternal alloc] init];
// STAssertTrue(agent.enabled, @"Agent disabled");
// }
// */
//
//
//
//@end
//
//
//#pragma mark Methods to override the NRMAReachability currentReachabilityStatus method
//
//NetworkStatus ReachableViaWWANMethod() {
//    return ReachableViaWWAN;
//}
//
//NetworkStatus NotReachableMethod() {
//    return NotReachable;
//}
