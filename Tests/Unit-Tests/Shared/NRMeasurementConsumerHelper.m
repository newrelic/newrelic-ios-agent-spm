//
//  NRMAMeasurementCosumerHelper.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/23/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMeasurementConsumerHelper.h"
#import "NRLogger.h"

@implementation NRMAMeasurementConsumerHelper

- (void) consumeMeasurement:(NRMAMeasurement *)measurement {
    NRLOG_VERBOSE(@"Measurement: %@",measurement);
    self.result = measurement;
}
@end
