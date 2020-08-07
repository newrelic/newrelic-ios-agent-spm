//
// Created by Bryce Buchanan on 5/18/17.
// Copyright (c) 2017 New Relic. All rights reserved.
//

#import "NRMAFlags.h"

@implementation NRMAFlags

static NRMAFeatureFlags __flags;
static BOOL __saltDeviceUUID = NO;

+ (void) enableFeatures:(NRMAFeatureFlags)featureFlags
{
    NRMAFeatureFlags flags = [self featureFlags];
    __flags = flags | featureFlags;
}

+ (void) disableFeatures:(NRMAFeatureFlags)featureFlags
{
    NRMAFeatureFlags flags = [self featureFlags];
    __flags = flags & ~featureFlags;
}

+ (NRMAFeatureFlags) featureFlags
{
    static dispatch_once_t defaultFeatureToken;
    dispatch_once(&defaultFeatureToken,
                  ^{
                      //enable default features here
                      __flags = __flags |
                              NRFeatureFlag_CrashReporting |
                              NRFeatureFlag_InteractionTracing |
                              NRFeatureFlag_NSURLSessionInstrumentation |
                              NRFeatureFlag_HttpResponseBodyCapture |
                              NRFeatureFlag_DefaultInteractions |
                              NRFeatureFlag_WebViewInstrumentation |
                              NRFeatureFlag_HandledExceptionEvents |
                              NRFeatureFlag_NetworkRequestEvents | 
                              NRFeatureFlag_RequestErrorEvents;
                  });
    return __flags;
}

+ (void) setFeatureFlags:(NRMAFeatureFlags)featureflags
{
    //for testing only
    [self featureFlags]; //to prime the flags.
    __flags = featureflags;
}

+ (BOOL) shouldSaltDeviceUUID {
    return __saltDeviceUUID;
}

+ (void) setSaltDeviceUUID:(BOOL)enable {
    __saltDeviceUUID = enable;
}

+ (BOOL) shouldEnableHandledExceptionEvents {
    return ([NRMAFlags featureFlags] & NRFeatureFlag_HandledExceptionEvents) != 0;
}

+ (BOOL) shouldEnableGestureInstrumentation
{
    return ([NRMAFlags featureFlags] & NRFeatureFlag_GestureInstrumentation) != 0;
}

+ (BOOL) shouldEnableNSURLSessionInstrumentation
{
    return ([NRMAFlags featureFlags] & NRFeatureFlag_NSURLSessionInstrumentation) != 0;
}

+ (BOOL) shouldEnableExperimentalNetworkingInstrumentation
{
    return ([NRMAFlags featureFlags] & NRFeatureFlag_ExperimentalNetworkingInstrumentation) != 0;
}

+ (BOOL) shouldEnableSwiftInteractionTracing
{
    return ([NRMAFlags featureFlags] & NRFeatureFlag_SwiftInteractionTracing) != 0;
}

+ (BOOL) shouldEnableInteractionTracing
{
    return ([NRMAFlags featureFlags] & NRFeatureFlag_InteractionTracing) != 0;
}

+ (BOOL) shouldEnableCrashReporting
{
    return ([NRMAFlags featureFlags] & NRFeatureFlag_CrashReporting) != 0;
}

+ (BOOL) shouldEnableDefaultInteractions
{
    return ([NRMAFlags featureFlags] & NRFeatureFlag_DefaultInteractions) != 0;
}
+ (BOOL) shouldEnableHttpResponseBodyCapture
{
    return ([NRMAFlags featureFlags] & NRFeatureFlag_HttpResponseBodyCapture) != 0;
}

+ (BOOL) shouldEnableWebViewInstrumentation {
    return ([NRMAFlags featureFlags] & NRFeatureFlag_WebViewInstrumentation) != 0;
}

+ (BOOL) shouldEnableRequestErrorEvents {
    return ([NRMAFlags featureFlags] & NRFeatureFlag_RequestErrorEvents) != 0;
}

+ (BOOL) shouldEnableNetworkRequestEvents {
    return ([NRMAFlags featureFlags] & NRFeatureFlag_NetworkRequestEvents) != 0;
}

+ (BOOL) shouldEnableDistributedTracing {
    return ([NRMAFlags featureFlags] & NRFeatureFlag_DistributedTracing) != 0;
}

@end
