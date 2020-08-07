//
//  NRHTTPErrorCountingMetricProducer.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/26/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NRMAMeasurementConsumer.h"
#import "NRMAHarvestableHTTPErrors.h"
@interface NRMAHTTPErrorCountingMeasurementProducer : NRMAMeasurementConsumer
- (id) init;
@end
