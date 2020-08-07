//
//  NRMACrashReporterRecorder.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/8/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAHarvestAware.h"

#define kNRMAUncaughtExceptionTag @"UncaughtExceptionHandler"

#define kNRMAExceptionHandler_Flurry      @"Flurry"

#define kNRMAExceptionHandler_Crashlytics @"Crashlytics"

#define kNRMAExceptionHandler_Crittercism @"Crittercism"

#define kNRMAExceptionHandler_Hockey      @"Hockey"

#define kNRMAExceptionHandler_TestFlight  @"TestFlight"

@interface NRMACrashReporterRecorder : NSObject <NRMAHarvestAware>
@property(assign) void* uncaughtExceptionHandler;
@property(strong) NSString* handlerLabel;

- (instancetype) init;

- (BOOL) isCrittercismDefined;
- (BOOL) isCrashlyticsDefined;
- (BOOL) isHockeyDefined;
- (BOOL) isTestFlightDefined;
- (BOOL) isFlurryDefined;

@end
