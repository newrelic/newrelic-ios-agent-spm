//
//  NRMAMeasurementPool.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/20/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMeasurementPool.h"
#import "NRLogger.h"
@interface NRMAMeasurementPool ()
@property(atomic) BOOL shouldAcceptMeasurements;
@end
@implementation NRMAMeasurementPool



- (id) init
{
    self = [super initWithType:NRMAMT_Any];
    if (self){
        self.shouldAcceptMeasurements = YES;
        self.producers = [[NSMutableDictionary alloc] init];
        self.consumers = [[NSMutableDictionary alloc] init];

        [self addMeasurementProducer:self];
        
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        _identifier = CFBridgingRelease(CFUUIDCreateString(NULL, theUUID));
        CFRelease(theUUID);
    }
    return self;
}


- (void) shutdown
{
    self.shouldAcceptMeasurements = NO;

    @synchronized(self.producers) {
        self.producers = nil;
    }

    @synchronized(self.consumers) {
        self.consumers = nil;
    }
}

- (void) addMeasurementProducer:(id<NRMAProducerProtocol>)producer
{
    if (!self.shouldAcceptMeasurements) {
        return;
    }
    @synchronized(self.producers)
    {
        NSNumber* typeKey = [NSNumber numberWithInt:producer.measurementType];
        
        
        if ([[self.producers objectForKey:typeKey] containsObject:producer]) {
            NRLOG_VERBOSE(@"Attepted to add the same MeasurementProducer %@ multiple times.",producer);
            return;
        }
        
        NSMutableArray* producerList = [self.producers objectForKey:typeKey];
        if (producerList == nil) {
            producerList = [[NSMutableArray alloc] init];
            [self.producers setObject:producerList forKey:typeKey];
        }
        
        [producerList addObject:producer];
    }
}

- (void) removeMeasurementProducer:(id<NRMAProducerProtocol>)producer
{
    @synchronized(self.producers) {
        NSNumber* typeKey = [NSNumber numberWithInt:producer.measurementType];
        if (![[self.producers objectForKey:typeKey] containsObject:producer]) {
            NRLOG_VERBOSE(@"Attempted to remove MeasurementProducer %@ which is not registered.",producer);
            return;
        }
        
        [[self.producers objectForKey:typeKey] removeObject:producer];
    }
}


- (void) addMeasurementConsumer:(id<NRMAConsumerProtocol>)consumer
{
    if (!self.shouldAcceptMeasurements) {
        return;
    }
    @synchronized(self.consumers) {
        NSNumber* typeKey = [NSNumber numberWithInt:consumer.measurementType];
        if ([[self.consumers objectForKey:typeKey] containsObject:consumer]) {
            NRLOG_VERBOSE(@"Attempted to add the same MeasurementConsumer %@ multiple times.",consumer);
            return;
        }
        NSMutableArray* consumerList = [self.consumers objectForKey:typeKey];
        if (consumerList == nil) {
            consumerList = [NSMutableArray array];
            [self.consumers setObject:consumerList forKey:typeKey];
        }
        [consumerList addObject:consumer];
    }
}
- (void) removeMeasurementConsumer:(NRMAMeasurementConsumer*)consumer
{
    
    @synchronized(self.consumers) {
        NSNumber* typeKey = [NSNumber numberWithInt:consumer.measurementType];
        NSMutableSet *consumerSet = [self.consumers objectForKey:typeKey];
        if ([consumerSet containsObject:consumer]) {
            [consumerSet removeObject:consumer];
        }
    }
}

- (void) broadcastMeasurements
{
    if (!self.shouldAcceptMeasurements) {
        return;
    }
    @synchronized(self.consumers) {
        @synchronized(self.producers) {
            NSMutableDictionary* allMeasurements = [NSMutableDictionary dictionary];
            for (NSNumber* numType in self.producers.allKeys) {
                for (NRMAMeasurementProducer* producer in [self.producers objectForKey:numType]) {
                    NSDictionary* measurements = [producer drainMeasurements];
                    [self combineMeasurementDictionary:allMeasurements withMeasurementDictionary:measurements];
                }
            }

            //prepare consumer list
            NSMutableArray* consumers = [NSMutableArray array];
            for (NSNumber* key in allMeasurements.allKeys) {
                for (NRMAMeasurementConsumer* consumer in [self.consumers objectForKey:key]){
                    if (![consumers containsObject:consumer]) {
                        [consumers addObject:consumer];
                    }
                }
            }

            NSArray* anyConsumers = [self.consumers objectForKey:[NSNumber numberWithInt:NRMAMT_Any]];
            if ([anyConsumers count]) {
                [consumers addObjectsFromArray:anyConsumers];
            }
            
            for (NRMAMeasurementConsumer* consumer in consumers) {
                NSNumber* typeKey = [NSNumber numberWithInt:consumer.measurementType];
                NSMutableDictionary* measurements = nil;

                if (consumer.measurementType == NRMAMT_Any) {
                    measurements = allMeasurements;
                } else {
                    measurements = [NSMutableDictionary dictionary];
                    NSSet* measurementSet = [allMeasurements objectForKey:typeKey];
                    if ([measurementSet count]) {
                        [measurements setObject:measurementSet forKey:typeKey];
                    }
                }
                
                [consumer consumeMeasurements:measurements];
            }
        }
    }
}

- (void)consumeMeasurement:(NRMAMeasurement *)measurement
{
    if (!self.shouldAcceptMeasurements) {
        return;
    }
    @synchronized(self.producers) {
        [self produceMeasurement:measurement];
    }
}

- (void) consumeMeasurements:(NSDictionary*)measurements
{
    if (!self.shouldAcceptMeasurements) {
        return;
    }
    @synchronized(self.producers) {
        [self produceMeasurements:measurements];
    }
}

- (NRMAMeasurementType) measurementType {
    return NRMAMT_Any;
}

- (void) combineMeasurementDictionary:(NSMutableDictionary*)dictionary1
            withMeasurementDictionary:(NSDictionary*)dictionary2
{
    for (NSNumber* key in dictionary2) {
        id value2 = [dictionary2 objectForKey:key];
        if (value2) {
            if ([dictionary1.allKeys containsObject:key]) {
                [[dictionary1 objectForKey:key] unionSet:value2];
            } else {
                [dictionary1 setObject:value2 forKey:key];
            }
        }
    }
}

@end

