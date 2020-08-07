//
//  NRMAScopedMeasurement.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/25/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAScopedMeasurement.h"
#import "NRMAHarvestableHTTPError.h"
#import "NRMAHarvestableHTTPTransaction.h"
#import "NRMAHTTPErrorMeasurement.h"
#import "NRMAHTTPTransactionMeasurement.h"
#import "NRMAHarvestableHTTPTransaction.h"
@interface NRMAScopedMeasurement (private)
@end
@implementation NRMAScopedMeasurement
- (instancetype) initWithMeasurement:(NRMAMeasurement *)measurement {
    self = [super initWithType:NRMA_HARVESTABLE_ARRAY];
    if (self) {
        self.startTime = (long long)measurement.startTime;
    }
    return self;
}

- (id)JSONObject
{
    return [NSMutableArray array];
}
@end
