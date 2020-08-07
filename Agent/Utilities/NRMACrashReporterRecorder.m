//
//  NRMACrashReporterRecorder.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/8/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMACrashReporterRecorder.h"
#import "NRMAMeasurements.h"
#import "NRConstants.h"
#import <objc/runtime.h>
#import <dlfcn.h>

#define kNRMAUncaughtExceptionTag @"UncaughtExceptionHandler"

#define kNRMAExceptionHandler_Flurry      @"Flurry"

#define kNRMAExceptionHandler_Crashlytics @"Crashlytics"

#define kNRMAExceptionHandler_Crittercism @"Crittercism"

#define kNRMAExceptionHandler_Hockey      @"Hockey"

#define kNRMAExceptionHandler_TestFlight  @"TestFlight"

@interface NRMACrashReporterRecorder (private)
@property(assign) void* uncaughtExceptionHandler;
@property(strong) NSString* handlerLabel;
@end

@implementation NRMACrashReporterRecorder

- (instancetype) init {
    self = [super init];
    if (self) {
    }
    return self;
}


-(void) onHarvestBefore
{
    [self generate3rdPartySDKMetrics];
}


- (void) generate3rdPartySDKMetrics
{
    [self generateCrashlyticsMetrics];
    [self generateCrittercismMetrics];
    [self generateFlurryMetrics];
    [self generateHockeyMetrics];
    [self generateTestFlightMetrics];
}

- (void) generateTestFlightMetrics
{
    if ([self isTestFlightDefined]) {
        [NRMAMeasurements recordAndScopeMetricNamed:[NSString stringWithFormat:@"%@/%@/%@",kNRAgentHealthPrefix,
                                                                                         kNRMAUncaughtExceptionTag,
                                                                                         kNRMAExceptionHandler_TestFlight]
                                            value:@1];
    }
}
- (void) generateCrashlyticsMetrics
{
    if ([self isCrashlyticsDefined]) {
        [NRMAMeasurements recordAndScopeMetricNamed:[NSString stringWithFormat:@"%@/%@/%@",kNRAgentHealthPrefix,
                                                                                         kNRMAUncaughtExceptionTag,
                                                                                         kNRMAExceptionHandler_Crashlytics]
                                            value:@1];
    }
}

- (void) generateCrittercismMetrics
{
    if ([self isCrittercismDefined]) {
        [NRMAMeasurements recordAndScopeMetricNamed:[NSString stringWithFormat:@"%@/%@/%@",kNRAgentHealthPrefix,
                                                                                         kNRMAUncaughtExceptionTag,
                                                                                         kNRMAExceptionHandler_Crittercism]
                                                                       value:@1];
    }
}

- (void) generateFlurryMetrics
{
    if ([self isFlurryDefined]) {
        [NRMAMeasurements recordAndScopeMetricNamed:[NSString stringWithFormat:@"%@/%@/%@",kNRAgentHealthPrefix,
                                                                                         kNRMAUncaughtExceptionTag,
                                                                                         kNRMAExceptionHandler_Flurry]
                                            value:@1];
    }
}

- (void) generateHockeyMetrics
{
    if ([self isHockeyDefined]) {
        [NRMAMeasurements recordAndScopeMetricNamed:[NSString stringWithFormat:@"%@/%@/%@",kNRAgentHealthPrefix,
                                                                                         kNRMAUncaughtExceptionTag,
                                                                                         kNRMAExceptionHandler_Hockey]
                                            value:@1];
    }
}

- (BOOL) isCrittercismDefined
{
    static BOOL isDefined = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       isDefined = (objc_lookUpClass("Crittercism") != NULL);
    });

    return isDefined;
}

- (BOOL) isCrashlyticsDefined
{
    static BOOL isDefined = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isDefined = (objc_lookUpClass("Crashlytics") != NULL);
    });

    return isDefined;
}

- (BOOL) isFlurryDefined
{
    static BOOL isDefined = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isDefined = (objc_lookUpClass("Flurry") != NULL);
    });

    return isDefined;
}

- (BOOL) isHockeyDefined
{
    static BOOL isDefined = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isDefined = (objc_lookUpClass("BITHockeyManager") != NULL);
    });

    return isDefined;
}

- (BOOL) isTestFlightDefined
{
    static BOOL isDefined = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isDefined = (objc_lookUpClass("TestFlight") != NULL);
    });

    return isDefined;
}

@end
