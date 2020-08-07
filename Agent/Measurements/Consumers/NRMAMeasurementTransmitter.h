//
//  NRHTTPErrorTraceGenerator.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/10/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMeasurementConsumer.h"
#import "NRMAMeasurementPool.h"

/*
 *  NRMeasurementTransmitter
 *  
 *  This consumer will take measurements of {type} and added them to 
 *  {destinationPool} by produce and then immdeiately broadcast.
 *
 *  EG: used to gather specific types from the main NRMeasurements' pool
 *      and transfer the relevent ones to the active NRTraces.
 */

@interface NRMAMeasurementTransmitter : NRMAMeasurementConsumer
@property(atomic,assign) NRMAMeasurementPool* destinationPool;
- (id) initWithType:(NRMAMeasurementType)type
    destinationPool:(NRMAMeasurementPool*)pool;
@end
