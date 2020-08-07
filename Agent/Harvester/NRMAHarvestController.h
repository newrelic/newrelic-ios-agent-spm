//
//  NRMAHarvest.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/3/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//
#ifdef __cplusplus
 extern "C" {
#endif

#import <Foundation/Foundation.h>
#import "NRMAHarvester.h"
#import "NRMAHarvestTimer.h"
#import "NRMAHarvestableMetric.h"
#import "NRMAHarvestableActivity.h"
#import "NRMANamedValueMeasurement.h"
#import "NRMAHarvestableAnalytics.h"


@interface NRMAHarvestController : NSObject

+ (NRMAHarvestController*) harvestController;

+ (void) setPeriod:(long long)period;

+ (void) initialize:(NRMAAgentConfiguration*)configuration;

+ (void) start;

+ (void) stop;

- (void) createHarvester;

- (NRMAHarvester*) harvester;

- (NRMAHarvestTimer*) harvestTimer;

- (void) deinitialize;

//+ (BOOL) shouldCollectNetworkTraces;
+ (BOOL) shouldNotCollectTraces;

#pragma mark - HarvestController interface

+ (NRMAHarvesterConfiguration*) configuration;

+ (NRMAHarvestData*) harvestData;

+ (void) addHarvestListener:(id<NRMAHarvestAware>)obj;

+ (void) removeHarvestListener:(id<NRMAHarvestAware>)obj;

#pragma mark - for testing

+ (BOOL) harvestNow;


#pragma mark - for crash handling

+ (void) recovery;


#pragma mark - harvest data interface

+ (void) addHarvestableHTTPTransaction:(NRMAHarvestableHTTPTransaction*)transaction;

+ (void) addHarvestableHTTPError:(NRMAHarvestableHTTPError*)error;

+ (void) addNamedValue:(NRMANamedValueMeasurement*)measurement;

+ (void) addHarvestableActivity:(NRMAHarvestableActivity*)activity;

+ (void) addHarvestableAnalytics:(NRMAHarvestableAnalytics*)analytics;
@end

#ifdef __cplusplus
}
#endif
