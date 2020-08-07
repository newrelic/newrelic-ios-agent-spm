//
//  NRMAScopedMeasurement.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/25/13.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAHarvestableArray.h"
#import "NRMAMeasurement.h"
#import "NRMAThreadInfo.h"
@interface NRMAScopedMeasurement : NRMAHarvestableArray
- (instancetype) initWithMeasurement:(NRMAMeasurement*)measurement;
@property(atomic,strong) NRMAHarvestableArray* measurement;
@property(atomic) long long startTime;
@property(atomic) NRMAThreadInfo* threadInfo;

@end
