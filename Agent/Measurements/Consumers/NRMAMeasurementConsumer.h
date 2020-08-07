//
//  NRMAMeasurementConsumer.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/20/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAConsumerProtocol.h"
@interface NRMAMeasurementConsumer : NSObject <NRMAConsumerProtocol>
{
    NRMAMeasurementType _measurementType;
}
@property(readonly) NRMAMeasurementType measurementType;

- (id) initWithType:(NRMAMeasurementType)type;
- (void) consumeMeasurement:(NRMAMeasurement *)measurement;
- (void) consumeMeasurements:(NSDictionary*)measurements;

@end
