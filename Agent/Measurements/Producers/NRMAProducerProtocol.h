//
//  NRMAProducerProtocol.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/20/13.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAMeasurementType.h"
#import "NRMAMeasurement.h"
@protocol NRMAProducerProtocol <NSObject>
@required
- (NRMAMeasurementType) measurementType;
- (void) produceMeasurement:(NRMAMeasurement*)measurement;
- (void) produceMeasurements:(NSDictionary*)measurements;
- (NSDictionary*) drainMeasurements;
@end
