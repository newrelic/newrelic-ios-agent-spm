//
//  NRTraceMachine.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/9/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRTimer.h"
#import "NRConstants.h"

@class NRMAActivityTrace;
@class NRMATrace;
@class NRTraceMachineInterface;


//used to synchronized start and end traces. 
extern NSString* const kNRMAStartAndEndTracingLock;
extern NSString* const kNRMACustomInteractionIdentifier;

@interface NRMATraceController : NSObject


+ (NSTimeInterval) healthyTraceTimeout;
+ (NSTimeInterval) unhealthyTraceTimeout;


+ (void) exitCustomMethodWithTimer:(NRTimer*)timer;

+ (NSString*) getCurrentActivityName;

+ (void) startTracingWithRootTrace:(NRMATrace*)rootTrace;

+ (NRMATrace*) startTracing:(BOOL)persistentTrace;

+ (NRMATrace*) registerNewTrace:(NSString *)name
                   withParent:(NRMATrace*) parentTrace;

+ (BOOL) isInteractionObject:(id __unsafe_unretained)obj;

+ (void) startTracingWithName:(NSString *)name interactionObject:(id __unsafe_unretained)obj;

+ (BOOL) completeActivityTrace;

+ (NRMATrace*) enterMethod:(SEL)selector
           fromObjectNamed:(NSString*)objName
               parentTrace:(NRMATrace*)parentTrace
             traceCategory:(enum NRTraceType)category;

+ (NRMATrace*) enterMethod:(SEL)selector
           fromObjectNamed:(NSString*)objName
               parentTrace:(NRMATrace*)parentTrace
             traceCategory:(enum NRTraceType)category
                 withTimer:(NRTimer *)timer;

+ (BOOL) enterMethod:(NRMATrace*)parentTrace
                name:(NSString*)newTraceName;

+ (void) exitMethod;

+ (NRMATrace*) currentTrace;

+ (NSString*) currentScope;

+ (BOOL) isTracingActive;

+ (BOOL) shouldCollectTraces;

+ (void) cleanup; 

@end
