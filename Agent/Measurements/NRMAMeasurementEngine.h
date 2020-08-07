//
//  NRMAMeasurementEngine.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/22/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAMeasurementPool.h"
#import "NRMAMeasurementException.h"
#import "NRMAHarvestAware.h"

#import "NRMAHTTPTransactionMeasurementProducer.h"
#import "NRMAHTTPErrorCountingMeasurementProducer.h"
#import "NRMAHTTPErrorMeasurementProducer.h"
#import "NRMAActivityTraceMeasurementCreator.h"
#import "NRMAActivityTraceMeasurementProducer.h"
#import "NRMAMethodMeasurementProducer.h"
#import "NRMASummaryMeasurementConsumer.h"
#import "NRMAHarvestableHTTPTransactionGeneration.h"
#import "NRMANamedValueProducer.h"
#import "NRMAMachineMeasurementConsumer.h"

@interface NRMAMeasurementEngine : NSObject <NRMAHarvestAware>

@property(strong, atomic) NSMutableDictionary* activities;
@property(strong, atomic) NRMAMeasurementPool* rootMeasurementPool;

@property(strong, atomic) NRMAHTTPTransactionMeasurementProducer* httpTransactionMeasurementProducer;
@property(strong, atomic) NRMAHTTPErrorCountingMeasurementProducer* httpErrorCountingMeasurementsProducer;
@property(strong, atomic) NRMAHTTPErrorMeasurementProducer* httpErrorMeasurementProducer;
@property(strong, atomic) NRMAActivityTraceMeasurementCreator* activityTraceMeasurementCreator;
@property(strong, atomic) NRMAActivityTraceMeasurementProducer* activityTraceMeasurementProducer;
@property(strong, atomic) NRMAMethodMeasurementProducer* summaryMeasurementProducer;
@property(strong, atomic) NRMASummaryMeasurementConsumer* summaryMeasurementConsumer;
@property(strong, atomic) NRMAHarvestableHTTPTransactionGeneration* harvestableHTTPTransactionGenerator;
@property(strong, atomic) NRMANamedValueProducer* machineMeasurementsProducer;
@property(strong, atomic) NRMAMachineMeasurementConsumer* machineMeasurementsConsumer;

- (void) addMeasurementProducer:(id<NRMAProducerProtocol>)producer;
- (void) removeMeasurementProducer:(id<NRMAProducerProtocol>)producer;
- (void) addMeasurementConsumer:(id<NRMAConsumerProtocol>)consumer;
- (void) removeMeasurementConsumer:(id<NRMAConsumerProtocol>)consumer;
- (void) broadcastMeasurements;
@end
