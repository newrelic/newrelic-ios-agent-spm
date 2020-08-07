//
//  NRMachineMeasurementConsumer.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/30/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMeasurementConsumer.h"
#import "NRMAHarvestAware.h"
#import "NRMAMetricSet.h"
@interface NRMAMachineMeasurementConsumer : NRMAMeasurementConsumer <NRMAHarvestAware>
- (instancetype) init;
@end
