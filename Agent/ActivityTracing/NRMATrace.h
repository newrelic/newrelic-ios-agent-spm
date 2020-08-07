//
//  NRMATrace.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/9/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAConsumerProtocol.h"
#import "NRMACustomTrace.h"
@class  NRMATraceMachine;
#import "NRMAThreadInfo.h"
@interface NRMATrace : NSObject <NRMAConsumerProtocol>
@property(nonatomic,assign) double entryTimestamp;
@property(nonatomic,assign) double exitTimestamp;
@property(nonatomic,strong) NSString* name;
@property(nonatomic,strong) NSString* classLabel;
@property(nonatomic,strong) NSString* methodLabel;
@property(nonatomic,strong) NRMAThreadInfo* threadInfo;
@property(nonatomic,strong) NSMutableDictionary* parameters;
@property(nonatomic,assign) BOOL      persistent;
@property(nonatomic,strong) NSMutableSet* children; 
@property(atomic,weak)   NRMATraceMachine* traceMachine;
@property(nonatomic,strong)    NSMutableArray* scopedMeasurements;
@property(nonatomic,readonly) double exclusiveTimeMillis;
@property(nonatomic,readonly) double networkTimeMillis;
@property(nonatomic) enum NRTraceType category;
@property(nonatomic) BOOL   ignoreNode;
- (id) init;
- (id) initWithName:(NSString*)name
       traceMachine:(NRMATraceMachine*)traceMachine;

- (NSTimeInterval) durationInSeconds;
- (NSString*) metricName;
- (void) complete;
- (void) addChild:(NRMATrace*)trace;
- (void) calculateExclusiveTime;
@end
