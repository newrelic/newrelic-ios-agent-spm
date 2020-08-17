//
//  NewRelicAgentTests.h
//  NewRelicAgentTests
//
//  Created by Saxon D'Aubin on 6/20/12.
//  Copyright (c) 2012 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <UIKit/UIKit.h>

#import "NewRelicAgentInternal.h"
#import "NRMACPUVitals.h"
#import "NRMAReachability.h"
#import "NRMAMethodSwizzling.h"
#import "NewRelicAgent+Development.h"

// We just need a web page that has the agent running
#define TEST_URL @"http://www.google.com/"
#define TEST_UNCACHED_URL @"http://www.microsoft.com/"
#define TEST_REDIRECT_URL @"http://www.tappister.com/test/a/b"
#define TEST_REDIRECT_END_URL @"http://www.tappister.com/funk/c"

#define TEST_APPLICATION_TOKEN @"AAa2d4baa1094bf9049bb22895935e46f85c45c211"
#define TEST_COLLECTOR_HOST @"staging-mobile-collector.newrelic.com"
#define TEST_BUNDLE_ID @"com.newrelic.tests"
#define TEST_BAD_COLLECTOR_HOST @"smc-broken.newrelic.com"

//#define TEST_ACCOUNT_KEY @"bootstrap_newrelic_admin_license_key_000"
//#define TEST_COLLECTOR_HOST @"localhost:8081"

/* Macros for some commonly used test validations */
 
#define CHECK_AGENT_RESPONSE_HEADERS(dict) STAssertNotNil([(dict) valueForKey:NEW_RELIC_SERVER_METRICS_HEADER_KEY], @"X-NewRelic-App-Data header was not received");

#define CONFIRM_TRANSACTION_DATA [self waitForData]; \
STAssertNotNil([NewRelicAgentInternal transactionData], @"Transaction data list was nil"); \
STAssertEquals((unsigned)1, [NewRelicAgentInternal transactionData].count, @"Expected one value in transaction data list");

typedef BOOL(^ConditionalBlock)();

@interface WaitBlock : NSObject

@property (atomic, assign) ConditionalBlock condition;
@property (atomic, assign) BOOL completed;
@property (atomic, strong) NSDate *started;
@property (atomic, assign) NSTimeInterval timeout;

@end


/* Make internal methods publicly visible to our tests */
@interface NewRelicAgentInternal(UnitTests)

@property (nonatomic, readonly) NSNumber * serverTimestamp;
@property (nonatomic, readonly) NSNumber * harvestInterval;
@property (nonatomic, readonly) NSNumber * harvestTransactionCount;
@property (nonatomic, readonly) NSNumber * harvestTransactionAge;
@property (nonatomic, readonly) NSString * locatedCountry;
@property (nonatomic, readonly) NSString * locatedRegion;

- (NSString*)getFullCollectorAddress:(NSString*)partialAddress;
- (BOOL)isConnected;
- (BOOL)isDisabled;

//- (NSArray*)transactionData;
//- (NSArray*)errorData;
//- (NSDictionary*)supportabilityMetrics;

//- (void)clearServerState;
- (void)destroyAgent;

+ (void)setApplicationName:(NSString *)appName andVersion:(NSString *)appVersion andBundleId:(NSString *)bundleId;


- (NSMutableDictionary *)getMachineMeasurements:(CPUTime)cpuTime withDuration:(NSTimeInterval)duration;
@end


@class NewRelicAgentTests;

extern NRMANetworkStatus ReachableViaWWANMethod();
extern NRMANetworkStatus NotReachableMethod();

extern BOOL _NRMAAgentTestModeEnabled;
extern BOOL _NRMAAgentSyncConnectEnabled;

@interface RequestDelegateBase : NSObject <NSURLConnectionDelegate>
//@property (atomic, assign) BOOL requestComplete;
//@property (atomic, strong) NSURLRequest* request;
//@property (atomic, strong) NSHTTPURLResponse* response;
//@property (atomic, strong) NSError* error;
//- (void)blockUntilDone:(NewRelicAgentTests*)test;
@end


@interface RequestDelegate : RequestDelegateBase
@end

/*
 A helper NSURLProtocol class that will log all request instances it sees but not interfere with any processing
 */
@interface MonitorURLProtocol : NSURLProtocol
@property (atomic, strong) NSMutableArray *capturedRequests;
+ (MonitorURLProtocol *)sharedInstance;
- (void)clearHeaders;
@end


@interface NewRelicAgentTests : XCTestCase

- (void)clearDisableFlag;

- (void)waitForData;
- (void)waitForDataExists:(BOOL)exists;
- (void)waitForCountedTransactions:(NSUInteger)count withTimeout:(NSTimeInterval)timeout;
- (void)waitForCondition:(ConditionalBlock)condition withTimeout:(NSTimeInterval)timeout;

- (void)hitGoogle;
- (void)hitGoogleWithError;

- (void)generateRealDataAndWait;
- (NSMutableURLRequest*)createRequest;

- (void)checkResponseHeadersIndirect:(NSDictionary *)dictionary;

@end



