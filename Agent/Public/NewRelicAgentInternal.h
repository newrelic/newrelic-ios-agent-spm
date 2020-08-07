//
//  NewRelicAgentInternal.h
//  NewRelicAgent
//
//  Created by Saxon D'Aubin on 6/12/12.
//  Copyright (c) 2012 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NewRelicFeatureFlags.h"
#import "NRMAMeasurements.h"
#import "NRMAHandledExceptions.h"
#import "NRMAUserActionFacade.h"

#define NEW_RELIC_APP_VERSION_HEADER_KEY        @"X-NewRelic-App-Version"
#define NEW_RELIC_OS_NAME_HEADER_KEY            @"X-NewRelic-OS-Name"


//// keys used for http error parameter map



// constants for user settings keys
#define NEWRELIC_CROSS_PROCESS_ID_SETTINGS_KEY              @"NewRelicCrossProcessId"
#define NEWRELIC_DATA_TOKEN_SETTINGS_KEY                    @"NewRelicDataToken"
#define NEWRELIC_SERVER_TIMESTAMP_SETTINGS_KEY              @"NewRelicServerTimestamp"
#define NEWRELIC_HARVEST_INTERVAL_SETTINGS_KEY              @"NewRelicHarvestInterval"

#define NEWRELIC_AGENT_DISABLED_VERSION_KEY @"NewRelicAgentDisabledVersion"

/*
 Defines the internal agent api.
 */
@interface NewRelicAgentInternal : NSObject

@property (nonatomic, readonly, assign) BOOL enabled;
@property(atomic,strong) NRMAAnalytics* analyticsController;
@property(atomic, strong) NRMAHandledExceptions* handledExceptionsController;
@property(atomic, strong) NRMAUserActionFacade* gestureFacade;

/*
 * Track the total number of successful network requests logged by the agent
 */
@property (nonatomic, readonly, assign) NSUInteger lifetimeRequestCount;

/*
 * Track the total number of failed network requests logged by the agent
 */
@property (nonatomic, readonly, assign) NSUInteger lifetimeErrorCount;

@property (atomic, readonly, strong) NRMAAgentConfiguration *agentConfiguration;

+ (void)startWithApplicationToken:(NSString*)appToken
              andCollectorAddress:(NSString*)CollectorUrl;

+ (void)startWithApplicationToken:(NSString*)appToken
              andCollectorAddress:(NSString*)CollectorUrl
         andCrashCollectorAddress:(NSString*)crashCollectorUrl;


- (NSDate*) getAppSessionStartDate;

+ (NewRelicAgentInternal*) sharedInstance;

- (NSString*) currentSessionId;

/*
 Returns whether or not we should be collecting HTTP errors. Exposed
 for ASI support.
 */
- (BOOL) collectNetworkErrors;
+ (BOOL) harvestNow;


@end

/*
 Categories that swizzle methods to intercept method calls implement this protocol.  The 
 initializeInstrumentation method of NewRelicAgentInternal calls NewRelicInitializeInstrumentation
 on each category.
 */
@protocol Instrumentation <NSObject>

/*
 Initializes method patching (swizzling) in a category.
 */
+(BOOL)NewRelicInitializeInstrumentation;


@end
