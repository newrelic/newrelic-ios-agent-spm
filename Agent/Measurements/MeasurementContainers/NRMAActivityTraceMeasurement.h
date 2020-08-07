//
//  NRMAActivityTraceMeasurement.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/11/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMeasurement.h"
#import "NRMAActivityTrace.h"
#import "NRMAInteractionDataStamp.h"
@interface NRMAActivityTraceMeasurement : NRMAMeasurement

@property(nonatomic,strong) NSString* traceName;
@property(nonatomic,strong) NRMATrace*  rootTrace;
@property(nonatomic,strong) NRMAInteractionDataStamp* lastActivity;
@property(atomic,strong) NSMutableDictionary* cpuVitals;
@property(atomic,strong) NSMutableDictionary* memoryVitals;

- (id) initWithActivityTrace:(NRMAActivityTrace*)trace;

@end
