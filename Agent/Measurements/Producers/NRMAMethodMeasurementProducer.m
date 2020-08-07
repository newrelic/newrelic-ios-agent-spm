//
//  NRMethodMeasurementProducer.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/31/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMethodMeasurementProducer.h"
#import "NRMATrace.h"
#import "NRMAMethodSummaryMeasurement.h"
@implementation NRMAMethodMeasurementProducer

- (instancetype) init {
    self =[super initWithType:NRMAMT_Method];
    if (self) {
        
    }
    return self;
}

@end
