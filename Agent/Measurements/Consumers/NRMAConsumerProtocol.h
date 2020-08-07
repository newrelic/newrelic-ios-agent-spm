//
//  NRMAConsumerProtocol.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/20/13.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAMeasurementType.h"
#import "NRMAMeasurement.h"
@protocol NRMAConsumerProtocol <NSObject>
@required
- (NRMAMeasurementType) measurementType;
- (void) consumeMeasurement:(NRMAMeasurement*)measurement;
- (void) consumeMeasurements:(NSDictionary*)measurements;
@end
