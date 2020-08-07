//
//  NRMAMeasurements.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/26/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAHTTPErrorCountingMeasurementProducer.h"
#import "NRMAHTTPErrorMeasurementProducer.h"
#import "NRMAHarvester.h"
#import "NRMAActivityTrace.h"
#import "NRMAMetric.h"
#import "NRMAHTTPTransaction.h"
#import "NRMAHTTPError.h"

#define kNRMAMetricException @"NRMARecordMetricException"

@interface NRMAMeasurements : NSObject

+ (void) recordSessionStartMetric;

+ (void) setBroadcastNewMeasurements:(BOOL)enabled;

+ (void) processCurrentSummaryMetricsWithTotalTime:(double)timeMillis
                                      activityName:(NSString*)name;
+ (void) initializeMeasurements;

+ (void) shutdown;

/*
 *   this will generate two metrics:
 *   Mobile/Activity/Network/<activityName>/time
 *   Mobile/Activity/Network/<activityName>/count
 *   where the value of /time is the total network duration of an instance of 
 *   <ActivityName>, and /count is the number of network requests that occurred 
 *   during the activity.
 */
+ (void) recordNetworkMetricsFromMetrics:(NSArray*)metrics
                  forActivity:(NSString*)activityName;

+ (NSString*) recordBackgroundScopedMetricNamed:(NSString*)name
                                     value:(NSNumber*)value;

+ (NSString*) recordAndScopeMetricNamed:(NSString *)name
                             value:(NSNumber *)value;


+ (void) process;
+ (void) addMeasurementConsumer:(id<NRMAConsumerProtocol>) consumer;
+ (void) removeMeasurementConsumer:(id<NRMAConsumerProtocol>)consumer;
+ (void) addMeasurementProducer:(id<NRMAProducerProtocol>)producer;
+ (void) removeMeasurementProducer:(id<NRMAProducerProtocol>)producer;
@end
