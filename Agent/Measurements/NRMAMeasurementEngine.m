//
//  NRMAMeasurementEngine.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/22/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMeasurementEngine.h"
@implementation NRMAMeasurementEngine

- (void) dealloc
{
    @synchronized([NRMAMeasurementEngine class]) {
        [self.rootMeasurementPool removeMeasurementProducer:self.rootMeasurementPool];
        self.rootMeasurementPool = nil;

        [self removeMeasurementProducer:self.httpErrorMeasurementProducer];
        self.httpErrorMeasurementProducer = nil;
        [self removeMeasurementProducer:self.httpTransactionMeasurementProducer];
        self.httpTransactionMeasurementProducer = nil;
        [self removeMeasurementProducer:self.activityTraceMeasurementProducer];
        self.activityTraceMeasurementProducer = nil;
        [self removeMeasurementProducer:self.summaryMeasurementProducer];
        self.summaryMeasurementProducer = nil;

        [self removeMeasurementConsumer:self.httpErrorCountingMeasurementsProducer];
        self.httpErrorCountingMeasurementsProducer = nil;
        [self removeMeasurementConsumer:self.activityTraceMeasurementCreator];
        self.activityTraceMeasurementCreator = nil;
        [self removeMeasurementConsumer:self.harvestableHTTPTransactionGenerator];
        self.harvestableHTTPTransactionGenerator = nil;
        [self removeMeasurementConsumer:self.summaryMeasurementConsumer];
        self.summaryMeasurementConsumer = nil;
    }
}

- (id) init
{
    self = [super init];
    if (self) {
        self.activities = [NSMutableDictionary dictionary];
        self.rootMeasurementPool = [[NRMAMeasurementPool alloc] init];

        self.httpErrorMeasurementProducer = [[NRMAHTTPErrorMeasurementProducer alloc] init];
        [self addMeasurementProducer:self.httpErrorMeasurementProducer];

        self.activityTraceMeasurementProducer = [[NRMAActivityTraceMeasurementProducer alloc] init];
        [self addMeasurementProducer:self.activityTraceMeasurementProducer];

        self.httpTransactionMeasurementProducer = [[NRMAHTTPTransactionMeasurementProducer alloc] init];
        [self addMeasurementProducer:self.httpTransactionMeasurementProducer];

        self.machineMeasurementsProducer = [[NRMANamedValueProducer alloc] init];
        [self addMeasurementProducer: self.machineMeasurementsProducer];

        self.summaryMeasurementProducer = [[NRMAMethodMeasurementProducer alloc] init];
        [self addMeasurementProducer:self.summaryMeasurementProducer];

        //Consumers
        self.summaryMeasurementConsumer = [[NRMASummaryMeasurementConsumer alloc] init];
        [self addMeasurementConsumer:self.summaryMeasurementConsumer];

        self.activityTraceMeasurementCreator = [[NRMAActivityTraceMeasurementCreator alloc] init];
        [self addMeasurementConsumer:self.activityTraceMeasurementCreator];

        self.httpErrorCountingMeasurementsProducer = [[NRMAHTTPErrorCountingMeasurementProducer alloc] init];
        [self addMeasurementConsumer:self.httpErrorCountingMeasurementsProducer];

        self.harvestableHTTPTransactionGenerator = [[NRMAHarvestableHTTPTransactionGeneration alloc] init];
        [self addMeasurementConsumer:self.harvestableHTTPTransactionGenerator];

        self.machineMeasurementsConsumer = [[NRMAMachineMeasurementConsumer alloc] init];
        [self addMeasurementConsumer:self.machineMeasurementsConsumer];
    }
    return self;
}

- (void) addMeasurementProducer:(id<NRMAProducerProtocol>)producer
{
    [self.rootMeasurementPool addMeasurementProducer:producer];
}

- (void) removeMeasurementProducer:(NRMAMeasurementProducer*)producer
{
    [self.rootMeasurementPool removeMeasurementProducer:producer];
}

- (void) addMeasurementConsumer:(NRMAMeasurementConsumer*)consumer
{
    [self.rootMeasurementPool addMeasurementConsumer:consumer];
}

- (void) removeMeasurementConsumer:(NRMAMeasurementConsumer*)consumer
{
    [self.rootMeasurementPool removeMeasurementConsumer:consumer];
}

- (void) broadcastMeasurements
{
    [self.rootMeasurementPool broadcastMeasurements];
}

@end
