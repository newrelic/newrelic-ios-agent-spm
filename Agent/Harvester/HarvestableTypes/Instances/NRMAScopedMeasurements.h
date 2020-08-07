//
//  NRMAScopedMeasurements.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/26/13.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAHarvestableArray.h"
#import "NRMAScopedMeasurement.h"
@interface NRMAScopedMeasurements : NRMAHarvestableArray
@property(atomic) NRMAMeasurementType measurementType;
@property(strong,atomic) NSMutableArray* measurements;
- (instancetype) initWithMeasurementType:(NRMAMeasurementType)type;
- (void) addScopedMeasurement:(NRMAScopedMeasurement*)measurement;
- (NSUInteger) count;
@end
