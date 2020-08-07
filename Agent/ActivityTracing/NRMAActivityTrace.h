//
//  NRMAActivityTrace.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/6/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMATrace.h"
#import "NRMAInteractionDataStamp.h"

@interface NRMAActivityTrace : NSObject
@property(nonatomic,strong) NSMutableDictionary* traces;

//used to identify the original object that initiated the activity trace
//generally just the memory address of the object. 
@property(nonatomic,strong) NSString          *initiatingObjectIdentifier;
@property(nonatomic,strong) NRMATrace         *rootTrace;
@property(atomic,strong) NSMutableSet    *missingChildren;
@property(nonatomic,assign) double      lastUpdated;
@property(atomic,assign)    BOOL            isComplete;
@property(nonatomic,strong) NSString        *type;
@property(nonatomic,strong) NSString        *name;
@property(nonatomic,strong) NSMutableDictionary *memoryVitals;
@property(nonatomic,strong) NSMutableDictionary *cpuVitals;
@property(nonatomic)        double          totalExclusiveTimeMillis;
@property(nonatomic)        double          totalNetworkTimeMillis;
@property(nonatomic)        NSUInteger       nodes;
@property(nonatomic)         double       startTime; //milliseconds
@property(nonatomic)         double       endTime;   //milliseconds
@property(strong)   NRMAInteractionDataStamp* lastActivityStamp;

- (id) initWithRootTrace:(NRMATrace*)rootTrace;
- (void) addTrace:(NRMATrace*)trace;
- (BOOL) hasMissingChildren;
- (void) complete;
- (void) recordVitalsThrottled;
- (NSTimeInterval) durationInSeconds;
- (BOOL) shouldRecord;
@end
