//
// Created by Bryce Buchanan on 5/18/17.
// Copyright (c) 2017 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NewRelicFeatureFlags.h"

@interface NRMAFlags : NSObject
+ (void) enableFeatures:(NRMAFeatureFlags)featureFlags;

+ (void) disableFeatures:(NRMAFeatureFlags)featureFlags;

+ (NRMAFeatureFlags) featureFlags;

+ (void) setFeatureFlags:(NRMAFeatureFlags)featureflags;

+ (BOOL) shouldEnableHandledExceptionEvents;

+ (BOOL) shouldEnableGestureInstrumentation;

+ (BOOL) shouldEnableNSURLSessionInstrumentation;

+ (BOOL) shouldEnableExperimentalNetworkingInstrumentation;

+ (BOOL) shouldEnableSwiftInteractionTracing;

+ (BOOL) shouldEnableInteractionTracing;

+ (BOOL) shouldEnableCrashReporting;

+ (BOOL) shouldEnableDefaultInteractions;

+ (BOOL) shouldEnableHttpResponseBodyCapture;

+ (BOOL) shouldEnableWebViewInstrumentation;

+ (BOOL) shouldEnableRequestErrorEvents;

+ (BOOL) shouldEnableNetworkRequestEvents;

+ (BOOL) shouldEnableDistributedTracing;


// private settings only for VW (jira:MOBILE-6635)
+ (void) setSaltDeviceUUID:(BOOL)enable;
+ (BOOL) shouldSaltDeviceUUID;


@end
