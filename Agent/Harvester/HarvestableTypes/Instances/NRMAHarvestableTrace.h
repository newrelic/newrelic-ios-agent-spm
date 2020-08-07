//
//  NRMAHarvestableTrace.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/12/13.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMATimedTraceSegment.h"
#import "NRMATrace.h"
#import "NRMAScopedMeasurements.h"
@interface NRMAHarvestableTrace : NRMATimedTraceSegment

- (id) initWithTrace:(NRMATrace*)trace;
@property(strong,nonatomic) NRMAScopedMeasurements* events;
@property(strong,nonatomic) NRMAScopedMeasurements* network;

@property(nonatomic,strong) NRMAThreadInfo* threadInfo;
@property(nonatomic,strong) NSMutableArray* subSegments;
@end
