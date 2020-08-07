//
//  NRMAMethodProfiler.h
//  NewRelicAgent
//
//  Created by Jeremy Templier on 5/23/13.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kInstrumentForTrace @"InstrumentForTrace"
#define kInstrumentForActivities @"InstrumentForActivities"

#import "NRMAMetricSet.h"
#import "NRMAMethodSwizzling.h"

typedef NSString* NRMAMethodColor;

extern const NRMAMethodColor NRMAMethodColorBlack;
extern const NRMAMethodColor NRMAMethodColorWhite;
extern const NRMAMethodColor NRMAMethodColorUnknown;

NRMAMethodColor NRMAMethodColorOther(NRMAMethodColor color);

@interface NRMAMethodProfiler : NSObject
{
    NSDictionary* tracingObjects;
    BOOL startTrace;
    NSString* profileName;
}
//
// Array of all the collected values for all the metrics
@property (atomic, strong) NRMAMetricSet *collectedMetrics;
@property (nonatomic, assign) float methodReplacementTime;

- (void) startMethodReplacement;
+ (NRMAMethodProfiler *)sharedInstance;
- (id)init;
#ifdef DEBUG
 + (void) resetskipInstrumentationOnceToken;
#endif
@end
