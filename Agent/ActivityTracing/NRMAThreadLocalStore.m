//
//  NRMAThreadLocalStore.m
//  NewRelicAgent
//
//  Created by Jonathan Karon on 2/20/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAThreadLocalStore.h"

#import "NRMATrace.h"
#import "NRLogger.h"
#import "NRMATaskQueue.h"
#import "NRConstants.h"
#import "NRMAMetric.h"
#import "NRMATraceController.h"

#import <pthread.h>

const NSString* NRMA_TRACE_FIELD_KEY = @"_nr_threadTrace";
const NSString* NRMA_TRACE_STACK_KEY = @"_nr_threadStackTrace";

@implementation NRMAThreadLocalStore

static NSString *__threadDictionaryLock = @"threadDictionaryLock";
static NSMutableDictionary* __threadDictionaries;


// Public methods - must acquire a lock and prevent reentrancy

/** return the currently active trace segment (i.e. frame ptr) for this thread */
+ (NRMATrace*)threadLocalTrace
{
    @synchronized(__threadDictionaryLock)
    {
        NSMutableDictionary *currentDict = [[self class] currentThreadDictionary];
        return  [currentDict objectForKey:NRMA_TRACE_FIELD_KEY];
    }
}

/** clear the thread's trace stack, and set rootTrace as the frame ptr and 0th item on the stack */
+ (void)setThreadRootTrace:(NRMATrace *)root
{
    if (root == nil) {
        NRLOG_VERBOSE(@"Attempted to load a nil trace.");
        return;
    }

    @synchronized(__threadDictionaryLock)
    {
        [NRMAThreadLocalStore setThreadLocalTrace:root];

        NSMutableArray *stack = [NRMAThreadLocalStore threadLocalStack];
        [stack removeAllObjects];
        [stack addObject:root];
    }

    NRLOG_VERBOSE(@"Trace %@ is now active", root);
}

/** delete thread-local data on all threads */
+ (void)destroyStore
{
    NSMutableDictionary *oldDict;

    @synchronized(__threadDictionaryLock)
    {
        oldDict = __threadDictionaries;
        __threadDictionaries = nil;
    }
    [oldDict removeAllObjects];
}

/** push childTrace onto the thread's stack and set it as the frame ptr.
 if parentTrace is not on the same thread this will clear the stack and set parentTrace as the 0th item before pushing childTrace. */

+ (BOOL) pushChild:(NRMATrace *)childTrace forParent:(NRMATrace *)parentTrace
{
    if (childTrace == nil || parentTrace == nil) {
        NRLOG_VERBOSE(@"<Activity: \"%@\">  Trace enterMethod has nil child or parent trace segment. p=%@, c=%@",[NRMATraceController getCurrentActivityName], parentTrace, childTrace);
        return NO;
    }
    BOOL parentIsOnSameThread = [self isThreadMatchForChild:childTrace parent:parentTrace];
    @synchronized(__threadDictionaryLock)
    {
        NSMutableArray *stack = [NRMAThreadLocalStore threadLocalStack];
        if (!parentIsOnSameThread) {
            //case for new thread
            [self prepareNewThread:stack child:childTrace withParent:parentTrace];
        } else {
            [self prepareSameThread:stack child:childTrace withParent:parentTrace];
        }
        [NRMAThreadLocalStore setThreadLocalTrace:childTrace];
        [stack addObject:childTrace];
    }

    return parentIsOnSameThread;
}

+ (int) prepareNewThread:(NSMutableArray*)stack child:(NRMATrace*)child withParent:(NRMATrace*)parent
{
    int error = 0;
    if (stack.count > 0) {
        NRLOG_VERBOSE(@"<Activity: \"%@\"> thread local stack is not empty! Entering thread %ud from %ud, p=%@, c=%@, stack=%@",
                      [NRMATraceController getCurrentActivityName],
                      child.threadInfo.identity,
                      parent.threadInfo.identity,
                      parent, child, stack);
        [NRMATaskQueue queue:[[NRMAMetric alloc]
                            initWithName:kNRSupportabilityPrefix@"/OrphanedThreadLocalStackEntries"
                            value:[NSNumber numberWithInteger:stack.count]
                            scope:@""]];
        error = 1;
        [stack removeAllObjects];
    }
    
    [stack addObject:parent];

    return error;
}

+ (int) prepareSameThread:(NSMutableArray*)stack child:(NRMATrace*)child withParent:(NRMATrace*)parent
{
    int error = 0;

            if ([NRMAThreadLocalStore threadLocalTrace] != parent) {
                if (![self validateIsSerialParent:parent child:child]) {
                    NRLOG_ERROR(@"<Activity: \"%@\"> threadLocalTrace is not parentTrace! On thread %ud, p=%@, c=%@, f=%@, stack=%@",
                                [NRMATraceController getCurrentActivityName],
                                child.threadInfo.identity,
                                parent, child, [NRMAThreadLocalStore threadLocalTrace], stack);
                    [NRMATaskQueue queue:[[NRMAMetric alloc]
                                        initWithName:kNRSupportabilityPrefix@"/ThreadLocalParentNotField"
                                        value:@1
                                        scope:@""]];
                    error = 1;
                }
            } else if ([stack lastObject] != parent) {
                if (![self validateIsSerialParent:parent child:child]) {
                    
                    NRLOG_ERROR(@"<Activity: \"%@\"> parentTrace is not at bottom of threadLocalStack! On thread %ud, p=%@, c=%@, f=%@, stack=%@",
                                [NRMATraceController getCurrentActivityName],
                                child.threadInfo.identity,
                                parent, child, [NRMAThreadLocalStore threadLocalTrace], stack);
                    [NRMATaskQueue queue:[[NRMAMetric alloc]
                                        initWithName:kNRSupportabilityPrefix@"/ThreadLocalParentNotOnStack"
                                        value:@1
                                        scope:@""]];

                    error = 2;
                }
            }
    return error;
}

+ (BOOL) isThreadMatchForChild:(NRMATrace*)child parent:(NRMATrace*)parent
{
    return child.threadInfo.identity == parent.threadInfo.identity;
}

+ (BOOL) validateIsSerialParent:(NRMATrace*)parent child:(NRMATrace*)child
{
    if (parent.threadInfo.identity == child.threadInfo.identity) {
        //this means the child executed serially in relation to the parent
        //on the same thread as the parent.
        //we want to perserve this relationship
        return child.entryTimestamp > parent.exitTimestamp;
    }
    return NO;
}
/** if the innermost element on the stack is equal to `trace` remove current trace from stack,
 set parent trace to be active on this thread, and return the parent trace
 returns YES if the trace's metric data should be recorded */
+ (BOOL)popCurrentTraceIfEqualTo:(NRMATrace*)trace returningParent:(NRMATrace *__autoreleasing *)parent
{
    *parent = nil;
    @synchronized(__threadDictionaryLock)
    {
        NSMutableDictionary *currentDict = [[self class] currentThreadDictionary];

        NRMATrace *currentTrace = [currentDict objectForKey:NRMA_TRACE_FIELD_KEY];
        NSMutableArray *stack = [currentDict objectForKey:NRMA_TRACE_STACK_KEY];

        if (trace.threadInfo.identity != pthread_mach_thread_np(pthread_self()))
        {
            // whoops, trace is on the wrong thread
            NRLOG_VERBOSE(@"<Activity: \"%@\"> popCurrentTrace: exited trace is not on the current thread! et=%@, tlc=%@",[NRMATraceController getCurrentActivityName], trace, currentTrace);
            return NO;
        }

        if (trace != currentTrace) {
            NRLOG_VERBOSE(@"<Activity: \"%@\"> popCurrentTrace: exited trace is not the current threadLocalTrace. et=%@, tlc=%@",[NRMATraceController getCurrentActivityName], trace, currentTrace);
        }

        if ([stack lastObject] != trace) {
            if ([stack containsObject:trace]) {
                while ([stack lastObject] != nil && [stack lastObject] != trace) {
                    [stack removeLastObject];
                }
            }
        }

        if ([stack lastObject] == trace) {
            [stack removeLastObject];
        }
        else
        {
            NRLOG_VERBOSE(@"<Activity: \"%@\"> popCurrentTrace: exited trace is not on the current stack! et=%@, tlc=%@",[NRMATraceController getCurrentActivityName], trace, stack);
        }

        *parent = [stack lastObject];

        // update the frame ptr to the parent (if on the same thread)
        if ((*parent).threadInfo.identity == trace.threadInfo.identity) {
            [currentDict setObject:(*parent) forKey:NRMA_TRACE_FIELD_KEY];
        }
        else {
            // or clean out the thread
            [[self class] cleanupCurrentThreadLocal];
        }

        return YES;
    }
}




// Internal only - should only be called if you already have a lock on __threadDictionaryLock


+ (NSMutableDictionary*)currentThreadDictionary
{
    if (!__threadDictionaries) {
        __threadDictionaries = [[NSMutableDictionary alloc] init];
    }

    NSString* threadID = [NSString stringWithFormat:@"%d",pthread_mach_thread_np(pthread_self())];
    NSMutableDictionary* threadDictionary = nil;

    threadDictionary = [__threadDictionaries objectForKey:threadID];
    if (!threadDictionary) {
        threadDictionary = [[NSMutableDictionary alloc] init];
        [__threadDictionaries setObject:threadDictionary forKey:threadID];
    }

    return threadDictionary;
}

+ (NSMutableArray*)threadLocalStack {
    NSMutableDictionary *currentDict = [NRMAThreadLocalStore currentThreadDictionary];

    NSMutableArray* array = [currentDict objectForKey:NRMA_TRACE_STACK_KEY];
    if ( array == nil) {
        array = [[NSMutableArray alloc] init];
        [currentDict setObject:array forKey:NRMA_TRACE_STACK_KEY];
    }

    return array;
}

+ (void) setThreadLocalTrace:(NRMATrace*)trace
{
    if (trace == nil) {
        NRLOG_ERROR(@"Attempted to set a nil trace to the thread  local dictionary");
        return;
    }

    NSMutableDictionary *currentDict = [NRMAThreadLocalStore currentThreadDictionary];
    [currentDict setObject:trace forKey:NRMA_TRACE_FIELD_KEY];
}



+ (void)cleanupCurrentThreadLocal
{
    if (__threadDictionaries) {
        NSString* threadID = [NSString stringWithFormat:@"%d",pthread_mach_thread_np(pthread_self())];
        [__threadDictionaries removeObjectForKey:threadID];
    }
}

// for testing only
+ (NSMutableDictionary*)threadDictionaries
{
    if (!__threadDictionaries) {
        __threadDictionaries = [[NSMutableDictionary alloc] init];
    }
    return __threadDictionaries;
}
@end
