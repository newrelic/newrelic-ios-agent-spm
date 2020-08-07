//
//  NewRelic.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 11/4/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMATraceController.h"
#import "NRConstants.h"
#import "NRMACustomTrace.h"
#import "NRCustomMetrics.h"
#import <objc/runtime.h>
#import "NRMAMeasurements.h"
#import "NewRelicAgentInternal.h"
#import "NRMAFlags.h"
#import "NewRelicInternalUtils.h"
#import "NRMAExceptionHandler.h"
#import "NRMATaskQueue.h"
#import "NRMAHTTPTransaction.h"
#import "NRMAHTTPError.h"
#import "NRMATraceMachineAgentUserInterface.h"
#import "NRMAThreadInfo.h"
#import "NRMAAnalytics.h"
#import "NRMAKeyAttributes.h"
#import "NRMANetworkFacade.h"
#import "NewRelic.h"
#import "NRMAHarvestController.h"

#define kNRMA_NAME @"name"

@implementation NewRelic

+ (void) crashNow
{
    [self crashNow:nil];
}
+ (void) crashNow:(NSString*)message
{
    @throw [NSException exceptionWithName:@"NewRelicDemoException"
                                   reason:message?:@"This is a demo crash from +[NewRelic demoCrash:]"
                                 userInfo:nil];
}

+ (void)setApplicationVersion:(NSString *)versionString
{
    if ([NewRelicAgentInternal sharedInstance] != nil) {
        @throw [NSException exceptionWithName:@"InvalidUsageException" reason:[NSString stringWithFormat:@"'%@' may only be called prior to calling +[NewRelic startWithApplicationToken:]",NSStringFromSelector(_cmd)] userInfo:nil];
    }
    [NRMAAgentConfiguration setApplicationVersion:versionString];
}

+ (void) setApplicationBuild:(NSString *)buildNumber {
    if ([NewRelicAgentInternal sharedInstance] != nil) {
        @throw [NSException exceptionWithName:@"InvalidUsageException" reason:[NSString stringWithFormat:@"'%@' may only be called prior to calling +[NewRelic startWithApplicationToken:]",NSStringFromSelector(_cmd)] userInfo:nil];
    }
    [NRMAAgentConfiguration setApplicationBuild:buildNumber];
}

+ (void) recordHandledException:(NSException*)exception {
    [[NewRelicAgentInternal sharedInstance].handledExceptionsController recordHandledException:exception];
}

+ (void) recordHandledException:(NSException*)exception
           withAttributes:(NSDictionary*)attributes {
    [[NewRelicAgentInternal sharedInstance].handledExceptionsController recordHandledException:exception
                                                                                    attributes:attributes];
}

+ (void) recordError:(NSError* _Nonnull)error {
    [[NewRelicAgentInternal sharedInstance].handledExceptionsController recordError:error
                                                                         attributes:nil];
}

+ (void) recordError:(NSError* _Nonnull)error
          attributes:(NSDictionary* _Nullable)attributes
{
    [[NewRelicAgentInternal sharedInstance].handledExceptionsController recordError:error
                                                                         attributes:attributes];
}

+ (void) setPlatform:(NRMAApplicationPlatform)platform {
    [NRMAAgentConfiguration setPlatform:platform];
}

//hidden API
+ (void) setPlatformVersion:(NSString*)platformVersion {
    [NRMAAgentConfiguration setPlatformVersion:platformVersion];
}

+ (void) saltDeviceUUID:(BOOL)enabled {
    [NRMAFlags setSaltDeviceUUID:enabled];
}

+ (NSString*) currentSessionId {
    return [[[NewRelicAgentInternal sharedInstance] currentSessionId] copy];
}

+ (NSString*) crossProcessId {
    return [[[[NRMAHarvestController harvestController] harvester] crossProcessID] copy];
}

#pragma mark - manage feature flags
+ (void) enableFeatures:(NRMAFeatureFlags)featureFlags
{
    [NRMAFlags enableFeatures:featureFlags];
}

+ (void) disableFeatures:(NRMAFeatureFlags)featureFlags
{
    [NRMAFlags disableFeatures:featureFlags];
}

+ (void) enableCrashReporting:(BOOL)enabled
{
    if (enabled) {
        [NRMAFlags enableFeatures:NRFeatureFlag_CrashReporting];
    } else {
        [NRMAFlags disableFeatures:NRFeatureFlag_CrashReporting];
    }
}
#pragma mark - Starting up the agent

+ (void)startWithApplicationToken:(NSString*)appToken
{
    [NewRelicAgentInternal startWithApplicationToken:appToken
            andCollectorAddress:nil];
}


+ (void)startWithApplicationToken:(NSString*)appToken
                  withoutSecurity:(BOOL)disableSSL {

    [NewRelicAgentInternal startWithApplicationToken:appToken
                                 andCollectorAddress:nil];
}

+ (void)startWithApplicationToken:(NSString*)appToken andCollectorAddress:(NSString*)url
{
    [NewRelicAgentInternal startWithApplicationToken:appToken
                                 andCollectorAddress:url];
}

+ (void)startWithApplicationToken:(NSString*)appToken
              andCollectorAddress:(NSString*)url
         andCrashCollectorAddress:(NSString *)crashCollectorUrl
{
    [NewRelicAgentInternal startWithApplicationToken:appToken
                                 andCollectorAddress:url
                            andCrashCollectorAddress:crashCollectorUrl];
}
#pragma mark - NRMATimer helper

+ (NRTimer *)createAndStartTimer
{
    return [[NRTimer alloc] init];
}



#pragma mark - noticeNetwork helpers


+ (void)noticeNetworkRequestForURL:(NSURL *)url
                        httpMethod:(NSString *)httpMethod
                         withTimer:(NRTimer *)timer
                   responseHeaders:(NSDictionary *)headers
                        statusCode:(NSInteger)httpStatusCode
                         bytesSent:(NSUInteger)bytesSent
                     bytesReceived:(NSUInteger)bytesReceived
                      responseData:(NSData *)responseData
                         andParams:(NSDictionary *)params {

    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url];
    NSHTTPURLResponse*  response = [[NSHTTPURLResponse alloc] initWithURL:url
                                                               statusCode:httpStatusCode
                                                              HTTPVersion:@"1.1"
                                                             headerFields:headers];
    [request setHTTPMethod:httpMethod];
    [NRMANetworkFacade noticeNetworkRequest:request
                                   response:response
                                  withTimer:timer
                                  bytesSent:bytesSent
                              bytesReceived:bytesReceived
                               responseData:responseData
                                     params:params];
}

+ (void)noticeNetworkFailureForURL:(NSURL *)url
                        httpMethod:(NSString*)httpMethod
                         withTimer:(NRTimer *)timer
                    andFailureCode:(NSInteger)iOSFailureCode
{
    NSError* error = [NSError errorWithDomain:NSURLErrorDomain
                                         code:iOSFailureCode
                                     userInfo:nil];

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:httpMethod];

    [NRMANetworkFacade noticeNetworkFailure:request
                                  withTimer:timer
                                  withError:error];
}
#pragma mark - Interactions

+ (NSString*) startInteractionWithName:(NSString*)interactionName
{
    if (![NRMAFlags shouldEnableInteractionTracing]){
        NRLOG_VERBOSE(@"\"%@\" not executing; Interaction tracing is disabled.",NSStringFromSelector(_cmd));
        return nil;
    }

#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif

        return [NRMATraceMachineAgentUserInterface startCustomActivity:interactionName];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    }  @catch (NSException *exception) {
        [NRMAExceptionHandler logException:exception
                                     class:NSStringFromClass([self class])
                                  selector:NSStringFromSelector(_cmd)];
        [NRMATraceController cleanup];
        return nil;
    }

#endif
}


+ (void) stopCurrentInteraction:(NSString*)activityIdentifier
{
    if (![NRMAFlags shouldEnableInteractionTracing]){
        NRLOG_VERBOSE(@"\"%@\" not executing; Interaction tracing is disabled.",NSStringFromSelector(_cmd));
        return;
    }
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif
        [NRMATraceMachineAgentUserInterface stopCustomActivity:activityIdentifier];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    }  @catch (NSException *exception) {
        [NRMAExceptionHandler logException:exception
                                     class:NSStringFromClass([self class])
                                  selector:NSStringFromSelector(_cmd)];
        [NRMATraceController cleanup];
    }
#endif
}


#pragma mark - Method Tracing

+ (void) startTracingMethod:(SEL)selector
                     object:(id)object
                      timer:(NRTimer *)timer
                   category:(enum NRTraceType)category
{
   [self startTracingMethodNamed:NSStringFromSelector(selector)
                     objectNamed:NSStringFromClass([object class])
                           timer:timer
                        category:category];
}

+ (void) startTracingMethodNamed:(NSString*)methodName
                     objectNamed:(NSString*)objectName
                      timer:(NRTimer *)timer
                   category:(enum NRTraceType)category{

    if (![NRMAFlags shouldEnableInteractionTracing]){
        NRLOG_VERBOSE(@"\"%@\" not executing; Interaction tracing is disabled.",NSStringFromSelector(_cmd));
        return;
    }

    NSString* cleanSelectorString = [NewRelicInternalUtils cleanseStringForCollector:methodName];

    if (![NRMATraceController isTracingActive]) {
        NRLOG_VERBOSE(@"%@ attempted to start tracing method without active Interaction Trace",NSStringFromSelector(_cmd));
        return;
    }
    [NRMACustomTrace startTracingMethod:NSSelectorFromString(cleanSelectorString)
                             objectName:objectName
                                  timer:timer
                               category:category];


}


+ (void) endTracingMethodWithTimer:(NRTimer *)timer
{
    [timer stopTimer];
    if (![NRMAFlags shouldEnableInteractionTracing]){
        NRLOG_VERBOSE(@"\"%@\" not executing; Interaction tracing is disabled.",NSStringFromSelector(_cmd));
        //need to remove the associated object or else this will leak!
        return;
    }
    if (![NRMATraceController isTracingActive]) {
        NRLOG_VERBOSE(@"%@ attempted to end tracing method without active Interaction Trace",NSStringFromSelector(_cmd));
        //need to remove the associated object or else this will leak!
        if (timer) {
            objc_setAssociatedObject(timer, (__bridge const void *)(kNRTraceAssociatedKey), Nil, OBJC_ASSOCIATION_ASSIGN);
        }
        return;
    }
    [NRMACustomTrace endTracingMethodWithTimer:timer];
}

#pragma mark - Custom Metrics


+ (void) recordMetricWithName:(NSString *)name
                     category:(NSString *)category
{
    [NRCustomMetrics recordMetricWithName:name category:category];
}

+ (void) recordMetricWithName:(NSString *)name
                     category:(NSString *)category
                        value:(NSNumber *)value
{
    [NRCustomMetrics recordMetricWithName:name
                                 category:category
                                    value:value];
}

+ (void) recordMetricWithName:(NSString *)name
                     category:(NSString *)category
                        value:(NSNumber *)value
                   valueUnits:(NSString *)valueUnits
{
    [NRCustomMetrics recordMetricWithName:name
                                 category:category
                                    value:value
                               valueUnits:valueUnits];
}

+ (void) recordMetricWithName:(NSString *)name
                     category:(NSString *)category
                        value:(NSNumber *)value
                   valueUnits:(NSString *)valueUnits
                   countUnits:(NSString *)countUnits
{
    [NRCustomMetrics recordMetricWithName:name
                                 category:category
                                    value:value
                               valueUnits:valueUnits
                               countUnits:countUnits];
}

+ (BOOL) harvestNow
{
    return [NewRelicAgentInternal harvestNow];
}


#pragma mark - Custom attributes

+ (BOOL) setAttribute:(NSString*)name
                value:(id) value {
    return [[NewRelicAgentInternal sharedInstance].analyticsController setSessionAttribute:name
                                                                                     value:value
                                                                                persistent:YES];
}

+ (BOOL) incrementAttribute:(NSString*)name {
    return [NewRelic incrementAttribute:name value:@1];
}

+ (BOOL) incrementAttribute:(NSString*)name
                      value:(NSNumber*) value {

    return [[NewRelicAgentInternal sharedInstance].analyticsController incrementSessionAttribute:name
                                                                                           value:value
                                                                                      persistent:YES];
}

+ (BOOL) setUserId:(NSString*)userId {
    return [[NewRelicAgentInternal sharedInstance].analyticsController setSessionAttribute:@"userId"
                                                                                     value:userId
                                                                                persistent:YES];
}

+ (BOOL) removeAttribute:(NSString*)name {
    return [[NewRelicAgentInternal sharedInstance].analyticsController removeSessionAttributeNamed:name];
}

+ (BOOL) removeAllAttributes {
    return [[NewRelicAgentInternal sharedInstance].analyticsController removeAllSessionAttributes];
}

#pragma mark - Custom events


+ (BOOL) recordCustomEvent:(NSString*)eventType
                      name:(NSString*)name
                attributes:(NSDictionary*)attributes {

    NSMutableDictionary* mutableAttributes = attributes?[attributes mutableCopy]:[NSMutableDictionary new];
    if(name.length) {
        [mutableAttributes setValue:name forKey:kNRMA_NAME];
    }
    return [NewRelic recordCustomEvent:eventType attributes:mutableAttributes];
}

+ (BOOL) recordCustomEvent:(NSString*)eventType
                attributes:(NSDictionary*)attributes {
    return [[NewRelicAgentInternal sharedInstance].analyticsController addCustomEvent:eventType
                                                                       withAttributes:attributes];
}


+ (BOOL) recordBreadcrumb:(NSString* __nonnull)name
               attributes:(NSDictionary* __nullable)attributes
{
    return [[NewRelicAgentInternal sharedInstance].analyticsController addBreadcrumb:name
                                                                      withAttributes:attributes];
}

#pragma mark - Event retention settings

/*
 * this method sets the maximum allowed age of an event before analytics data is sent to New Relic
 * this means: once any recorded event reaches this age, all event data will be transmitted on the next
 * harvest cycle.
 */
+ (void) setMaxEventBufferTime:(unsigned int)seconds {
    [[NewRelicAgentInternal sharedInstance].analyticsController setMaxEventBufferTime:seconds];
}
/*
 * this method sets the maximum number of events buffered by the agent.
 * this means: once this many events have been recorded, new events have a statistical chance of overwriting
 * previously recorded events in the buffer.
 */
+ (void) setMaxEventPoolSize:(unsigned int)size {
    [[NewRelicAgentInternal sharedInstance].analyticsController setMaxEventBufferSize:size];
}

#pragma mark - Hidden APIs


/*
 * This function is built for hybird support and bridging with the browser agent
 */
+ (NSDictionary*) keyAttributes {
    return [NRMAKeyAttributes keyAttributes];
}


@end
