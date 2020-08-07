    //
//  NRMATraceController.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/9/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMeasurements.h"
#import "NRMATraceController.h"
#import "NRMATrace.h"
#import "NRMAActivityTrace.h"
#import "NRCustomMetrics+private.h"
#import "NRMAMeasurementTransmitter.h"
#import "NewRelicInternalUtils.h"
#import "NRMAHarvestController.h"
#import "NRMATaskQueue.h"
#import "NRMAExceptionHandler.h"
#import "NRMAMetric.h"
#import "NRMAThreadLocalStore.h"
#import "NRMALastActivityTraceController.h"
#import "NRMAInteractionHistoryObjCInterface.h"
#import <objc/runtime.h>
#import "NRMATraceMachine.h"
#import "NewRelicAgentInternal.h"
const NSTimeInterval NRMA_UNHEALTHY_TRACE_TIMEOUT = 60;
const NSTimeInterval NRMA_HEALTHY_TRACE_TIMEOUT = 0.5;

NSString* const kNRMACustomInteractionIdentifier = @"CUSTOM";
const int NRMA_MAX_NODE_LIMIT = 2000;

static NRMATraceMachine* __traceMachine;


NSString * const kNRMAStartAndEndTracingLock = @"startTracingLock";

@interface NRMATraceController()



+ (void) exitMethodWithTimestampMillis:(double)exitTimestampMilliseconds;
+ (void) completeTrace:(NRMATrace*)trace withExitTimestampMillis:(NSNumber*)exitTimestampMilliseconds;
+ (BOOL) completeActivityTraceWithExitTimestampMillis:(double)exitTimestampMilliseconds;

@end

@implementation NRMATraceController


static const NSString* __newRelicTraceMachAsyncLock = @"lock";
+ (NRMATraceMachine*)traceMachine
{
    @synchronized(__newRelicTraceMachAsyncLock) {
        return __traceMachine;
    }
}

+ (void) setTraceMachine:(NRMATraceMachine*)traceMachine
{
    @synchronized(__newRelicTraceMachAsyncLock) {
        __traceMachine = traceMachine;
    }
}


+ (void) cleanup
{
    NRMATraceMachine* localTraceMachine = [self traceMachine];
    [localTraceMachine.tracePool shutdown];
    [NRMATraceController clearMeasurementTransmitters];
    [self setTraceMachine:nil];
    [NRMAThreadLocalStore destroyStore];
}



static NSTimeInterval __unhealthyTraceTimeout;
+ (NSTimeInterval) unhealthyTraceTimeout
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __unhealthyTraceTimeout = NRMA_UNHEALTHY_TRACE_TIMEOUT;
    });

    return __unhealthyTraceTimeout;
}

+ (void) setUnhealthyTraceTimeout:(NSUInteger)unhealthyTraceTimeout
{
    __unhealthyTraceTimeout = unhealthyTraceTimeout;
}

static NSTimeInterval __healthyTraceTimeout;
+ (NSTimeInterval) healthyTraceTimeout
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __healthyTraceTimeout = NRMA_HEALTHY_TRACE_TIMEOUT;
    });

    return __healthyTraceTimeout;
}

+ (void) setHealthyTraceTimeout:(NSUInteger) healthyTraceTimeout
{
    __healthyTraceTimeout = healthyTraceTimeout;
}


#pragma mark - Static Functions
+ (NSString*) getCurrentActivityName
{
    NRMATraceMachine* localTraceMachine = [self traceMachine];
    NSString* scope = @"";
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif

        if (localTraceMachine) {
            scope = localTraceMachine.activityTrace.name;
        }
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                   class:NSStringFromClass([self class])
                                selector:NSStringFromSelector(@selector(getCurrentActivityName))];
    }
#endif
    return scope;
}


static NSString *__measurementLock = @"measurementTransmittersLock";

+ (void) clearMeasurementTransmitters
{
    NSMutableArray* measurementTransmitters = [self traceMachine].measurementTransmitters;
    @synchronized(measurementTransmitters) {
        for (NRMAMeasurementTransmitter* transmitter in measurementTransmitters) {
            [NRMAMeasurements removeMeasurementConsumer:transmitter];
        }
    }
}



+ (void) startTracingWithName:(NSString *)name interactionObject:(id __unsafe_unretained)obj
{
    @synchronized(kNRMAStartAndEndTracingLock) {
        NRLOG_VERBOSE(@"\"%@\" Activity started", name);
        [NRMATraceController startTracing:NO];
        [[[NewRelicAgentInternal sharedInstance] analyticsController] setLastInteraction:name];
        NRMATraceMachine* traceMach = [self traceMachine];
        traceMach.activityTrace.name = name;
        traceMach.activityTrace.initiatingObjectIdentifier = [NSString stringWithFormat:@"%p",obj];
        [NRMAInteractionHistoryObjCInterface insertInteraction:name startTime:(long long)(traceMach.activityTrace.startTime)];
    }
}

+ (BOOL) isInteractionObject:(id __unsafe_unretained)obj
{
    NRMATraceMachine* traceMach = [self traceMachine];
    if ([traceMach.activityTrace.initiatingObjectIdentifier isEqualToString:kNRMACustomInteractionIdentifier]) {
        //a special case, only custom activites are set to kNRMACustomInteractionIdentifier
        //and we want to prevent system activities from terminating a custom activity.
        return YES;
    }
    NSString* obj_addr = [NSString stringWithFormat:@"%p",obj];
    return [traceMach.activityTrace.initiatingObjectIdentifier isEqualToString:obj_addr];
}


// MARK: Bryce says persistentTrace is not used and a relic from the Android agent, no idea what it means.
+ (NRMATrace*) startTracing:(BOOL)persistentTrace
{
    @synchronized(kNRMAStartAndEndTracingLock) {
        NRMATrace* rootTrace = [[NRMATrace alloc] init];
        rootTrace.persistent = persistentTrace;
        rootTrace.name = @"UI_Thread";
        rootTrace.entryTimestamp = NRMAMillisecondTimestamp();
        
        NRLOG_VERBOSE(@"Started activity with root trace : %@", rootTrace);
        
        [NRMATraceController startTracingWithRootTrace:rootTrace];
        
        return rootTrace;
    }
}

//this method is used by the custom api :
//+ (void) startInteractionFromMethodName:(NSString*)selectorName
//                                 object:(id)object
//                         customizedName:(NSString*)interactionName
//                     cancelRunningTrace:(BOOL)cancel
+ (void) startTracingWithRootTrace:(NRMATrace*)rootTrace
{
    @synchronized(kNRMAStartAndEndTracingLock) {
        if ([NRMATraceController isTracingActive]) {
            [NRMATraceController completeActivityTrace];
        }

        [NRMATraceController cleanup];
        
        NSString* activityName = rootTrace.name;
        rootTrace.name = @"UI_Thread";

        NRMATraceMachine* traceMach = [[NRMATraceMachine alloc] initWithRootTrace:rootTrace];

        traceMach.activityTrace.name = activityName;

        rootTrace.traceMachine = traceMach;
        [NRMAThreadLocalStore setThreadRootTrace:rootTrace];
        [traceMach.tracePool addMeasurementConsumer:rootTrace];

        [self setTraceMachine:traceMach];
    }
}

+ (BOOL) completeActivityTrace
{
    return [self completeActivityTraceWithExitTimestampMillis:NRMAMillisecondTimestamp()];
}

+ (BOOL) completeActivityTraceWithTimer:(NRTimer*)timer
{
    return [self completeActivityTraceWithExitTimestampMillis:timer.endTimeMillis];
}


+ (BOOL) completeActivityTraceWithExitTimestampMillis:(double)exitTimestampMilliseconds
{
    @synchronized(kNRMAStartAndEndTracingLock) {
        if(![NRMATraceController isTracingActive]) {
            NRLOG_VERBOSE(@"completeTrace called while no trace was running.");
            return NO;
        }
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
        @try {
#endif  
            NRMATraceMachine* traceMach = [self traceMachine];

            [traceMach invalidateTimers]; //invalidate any timers that might be running.

            NRMAActivityTrace *activityTrace = traceMach.activityTrace;
            NRLOG_VERBOSE(@"\"%@\" Activity Completed.", activityTrace.name);


            [traceMach.tracePool removeMeasurementConsumer:activityTrace.rootTrace];

            [activityTrace complete];

            activityTrace.totalNetworkTimeMillis += activityTrace.rootTrace.networkTimeMillis;
            activityTrace.rootTrace.exitTimestamp = exitTimestampMilliseconds;

            NSNumber* totalTimeSeconds = [NSNumber numberWithDouble:[activityTrace durationInSeconds]];

            [NRCustomMetrics addMetric:[NSString stringWithFormat:@"Mobile/Activity/Name/%@", activityTrace.name]
                                 value:totalTimeSeconds]; //needs to be in seconds
            [NRCustomMetrics addMetric:[NSString stringWithFormat:@"Mobile/Activity/Background/Name/%@", activityTrace.name]
                                 value:totalTimeSeconds]; //needs to be in seconds

            [NRMALastActivityTraceController storeLastActivityStampWithName:activityTrace.name
                                                             startTimestamp:[NSNumber numberWithDouble:activityTrace.startTime]
                                                                   duration:[NSNumber numberWithDouble:(activityTrace.endTime - activityTrace.startTime)]];
            [NRMATaskQueue queue:activityTrace];

            [[NSNotificationCenter defaultCenter] postNotificationName:kNRInteractionDidCompleteNotification
                                                                object:activityTrace];

#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
        } @catch (NSException* exception) {
            [NRMAExceptionHandler logException:exception class:NSStringFromClass([self class]) selector:NSStringFromSelector(_cmd)];
        }
#endif
        [[self class] cleanup];
    }

    return YES;
}

+ (BOOL) newTraceSetup:(NRMATrace*)newTrace
           parentTrace:(NRMATrace*)parentTrace
{
    if (newTrace == nil || parentTrace == nil) {
        NRLOG_VERBOSE(@"<Activity : \"%@\"> : newTraceSetup called with a nil parent or child trace: p=%@, c=%@",
                      [NRMATraceController getCurrentActivityName],parentTrace, newTrace);
        return NO;
    }

    /* this code is invoked from enterMethod*
     
     rules:
        newTrace is executing on the current thread
        parentTrace may be the deepest open trace segment on the current thread or a trace from another thread
     
        assumptions if parentTrace is on the same thread:
            threadLocalTrace frame object is parentTrace
            threadLocalStack is allocated and lastObject is parentTrace
            newTrace should be pushed onto stack and set as active frame
        assumptions if parentTrace is not on the same thread:
            threadLocalStack is empty or nil
            threadLocalTrace frame is nil
            threadLocalStack should be allocated and contain [parentTrace, newTrace]
            newTrace should be set as active frame

        at the end of this method, newTrace should be on the stack and set as the current trace for the thread.

     */

    /*  it's important to set the entry timestamp of newTrace before we push
     *  push it onto the thread local store. because veriftying 
     *  the trace requires the entryTimestamp being set. */
    newTrace.entryTimestamp = NRMAMillisecondTimestamp();

    BOOL parentIsOnThisThread = [NRMAThreadLocalStore pushChild:newTrace forParent:parentTrace];

    return YES;
}


+ (BOOL) enterMethod:(NRMATrace*)parentTrace
                name:(NSString*)newTraceName
{
    if (![NRMATraceController isTracingActive]) {
        return NO;
    }
    NRMATrace* childTrace = [NRMATraceController registerNewTrace:newTraceName withParent:parentTrace];
    if (!childTrace) {
        return NO;
    }
    childTrace.entryTimestamp = NRMAMillisecondTimestamp();
    
    return [NRMATraceController newTraceSetup:childTrace
                             parentTrace:parentTrace];

}

+ (NRMATrace*) enterMethod:(SEL)selector
           fromObjectNamed:(NSString*)objName
               parentTrace:(NRMATrace*)parentTrace
             traceCategory:(enum NRTraceType)category
{
    return [[self class] enterMethod:selector
                     fromObjectNamed:objName
                         parentTrace:parentTrace
                       traceCategory:category
                           withTimer:nil];
}


+ (NRMATrace*) enterMethod:(SEL)selector
           fromObjectNamed:(NSString*)objName
               parentTrace:(NRMATrace*)parentTrace
             traceCategory:(enum NRTraceType)category
                 withTimer:(NRTimer *)timer
{
    if (![NRMATraceController isTracingActive]) {
        return nil;
    }

    NRMATrace* childTrace = [NRMATraceController registerNewTrace:[NSString stringWithFormat:@"%@#%@",objName,NSStringFromSelector(selector)]
                                                withParent:parentTrace];
    if (!childTrace) {
        return nil;
    }
    childTrace.category = category;
    childTrace.classLabel = objName;
    childTrace.methodLabel = NSStringFromSelector(selector);

    if (timer) {

        objc_setAssociatedObject(timer, (__bridge const void *)(kNRTraceAssociatedKey), childTrace, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif

        [NRMATraceController newTraceSetup:childTrace parentTrace:parentTrace];

        if (timer) {
            childTrace.entryTimestamp = timer.startTimeInMillis;
        }

#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                   class:NSStringFromClass([self class])
                                selector:NSStringFromSelector(_cmd)];
        if (timer) {

            objc_setAssociatedObject(timer, (__bridge const void *)(kNRTraceAssociatedKey), nil, OBJC_ASSOCIATION_ASSIGN);
        }
        [NRMATraceController cleanup];

        return nil;
    }
#endif

    return childTrace;
}

+ (NRMATrace*) registerNewTrace:(NSString *)name
                   withParent:(NRMATrace*) parentTrace
{
    NRMATraceMachine* localTraceMachine = [self traceMachine];
    @synchronized(localTraceMachine) {
        if (localTraceMachine == nil) {

            NRLOG_VERBOSE(@"tried to register a new trace but tracing is inactive");
            return nil;
        }
        
        NRMATrace* childTrace = [[NRMATrace alloc] initWithName:name
                                               traceMachine:localTraceMachine];
        
        if( localTraceMachine.activityTrace.nodes >= NRMA_MAX_NODE_LIMIT){
            NRLOG_VERBOSE(@"<Activity: \"%@\"> : NR_MAX_NODE_LIMIT(%d) reached dropping node",[NRMATraceController getCurrentActivityName],NRMA_MAX_NODE_LIMIT);
            childTrace.ignoreNode = YES;
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
            @try {
#endif
                [NRMAMeasurements recordAndScopeMetricNamed:kNRSupportabilityPrefix@"/InteractionTraceNodeLimited"
                                                    value:@1];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
            } @catch (NSException* exception) {
                [NRMAExceptionHandler logException:exception
                                           class:NSStringFromClass([self class])
                                        selector:NSStringFromSelector(_cmd)];
            }
#endif
        }
        
        [localTraceMachine.activityTrace addTrace:childTrace];
        
        [parentTrace addChild:childTrace];
        return childTrace;
    }
}

+ (void) exitMethod
{
    [self exitMethodWithTimestampMillis:NRMAMillisecondTimestamp()];
}
+ (void) exitCustomMethodWithTimer:(NRTimer*)timer
{
    [self exitMethodWithTimestampMillis:timer.endTimeMillis];
}

+ (void)exitMethodWithTimestampMillis:(double)exitTimestampMilliseconds
{
    [NRMATraceController completeTrace:[[self class] threadLocalTrace]
          withExitTimestampMillis:[NSNumber numberWithDouble:exitTimestampMilliseconds]];
}

+ (void) completeTrace:(NRMATrace*)trace withExitTimestampMillis:(NSNumber*)exitTimestampMilliseconds
{
    if (trace == nil) {
        return;
    }

    NRMATraceMachine *localTraceMachine = [self traceMachine];

    if (localTraceMachine == nil || ![NRMATraceController isTracingActive] || localTraceMachine != trace.traceMachine) {
        return;
    }

    NRMATrace* parentTrace = nil;
    BOOL recordTraceData = [NRMAThreadLocalStore popCurrentTraceIfEqualTo:trace
                                                        returningParent:&parentTrace];

    if (! recordTraceData) {
        return;
    }

    trace.exitTimestamp = [exitTimestampMilliseconds doubleValue]; //set end timestamp for trace

    NSTimeInterval totalTimeSeconds = [trace durationInSeconds]; //calculate total time in seconds
    [trace calculateExclusiveTime]; //calculate exclusive time

    NSString* metricName = [trace metricName]; // fetch metric name for trace
    [localTraceMachine.activityTrace recordVitalsThrottled]; // record vitals

    NSString* scope = @"";
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif
        if (totalTimeSeconds == 0) {
            totalTimeSeconds=1;
        }
        if (trace.threadInfo.identity == localTraceMachine.activityTrace.rootTrace.threadInfo.identity) {
            //if the trace is on the main thread we want a main metric
            scope = [NRMAMeasurements recordAndScopeMetricNamed:metricName value:[NSNumber numberWithDouble:totalTimeSeconds]];
        } else {
            //if the trace is on a background thread we want to make a background metric.
            scope = [NRMAMeasurements recordBackgroundScopedMetricNamed:metricName
                                                                value:[NSNumber numberWithDouble:totalTimeSeconds]];
        }
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        //failed to record proper metrics
        //don't add this trace to info
        [NRMAExceptionHandler logException:exception
                                   class:NSStringFromClass([self class])
                                selector:NSStringFromSelector(_cmd)];

    }
#endif
    //record exclusive time!

    BOOL recordSummaryTimes = YES;
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif
        [NRMATaskQueue queue:[[NRMAMetric alloc] initWithName:[NSString stringWithFormat:@"%@/ExclusiveTime", metricName]
                                   value:[NSNumber numberWithDouble:trace.exclusiveTimeMillis / 1000] //convert to seconds from milliseconds
                               scope:scope
                         produceUnscoped:YES]];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        recordSummaryTimes = NO;
        [NRMAExceptionHandler logException:exception
                                   class:NSStringFromClass([self class])
                                selector:NSStringFromSelector(_cmd)];
    }
#endif

    [NRMATaskQueue queue:trace];
    //accumulate a totalExclusiveTime to compare to total time
    //and avoid empty traces

    BOOL loggedExclusiveTime = NO;
    if (recordSummaryTimes) { // we don't want to record exclusive time if we fail to create a metric for it, right?
        loggedExclusiveTime = YES;
        localTraceMachine.activityTrace.totalExclusiveTimeMillis += trace.exclusiveTimeMillis;
    }

    localTraceMachine.activityTrace.totalNetworkTimeMillis += trace.networkTimeMillis;

    @synchronized(localTraceMachine.activityTrace.missingChildren){
        //now that this trace is complete it is no longer a missing child
        [localTraceMachine.activityTrace.missingChildren removeObject:trace];
        localTraceMachine.activityTrace.lastUpdated = NRMAMillisecondTimestamp();
    }
}



+ (NRMATrace*) getCurrentTrace
{
    NRMATrace *theTrace = [NRMAThreadLocalStore threadLocalTrace];

    if (theTrace) {
        return theTrace;
    } else {
        return [self traceMachine].activityTrace.rootTrace;
    }
}

+ (NRMATrace*) currentTrace
{
    if (![NRMATraceController isTracingActive]) {
        return nil;
    }
    return [NRMATraceController getCurrentTrace];
}

+ (NRMATrace*) threadLocalTrace
{
    return [NRMAThreadLocalStore threadLocalTrace];
}

+ (NSString*) currentScope
{
    return [NRMATraceController getCurrentTrace].name;
}
+ (BOOL) isTracingActive
{
    return [self traceMachine] != nil;
}

+ (BOOL) shouldCollectTraces
{
    NRMAHarvestData* harvestData = [[[NRMAHarvestController harvestController] harvester] harvestData];
    NRMAHarvesterConfiguration *configuration = [NRMAHarvestController configuration];

    if (harvestData == nil || configuration == nil)
        return YES;

    // todo: use fine grained AT capture rules later.
    int currentCount = harvestData.activityTraces.count;
    int maxCount = configuration.at_capture.maxTotalTraceCount;
    NRLOG_VERBOSE(@"Should collect traces: %d/%d", currentCount, maxCount);
    return harvestData.activityTraces.count < configuration.at_capture.maxTotalTraceCount;
}

+ (BOOL) shouldNotCollectTraces
{
    return ![self shouldCollectTraces];
}

@end
