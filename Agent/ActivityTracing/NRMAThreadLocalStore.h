//
//  NRMAThreadLocalStore.h
//  NewRelicAgent
//
//  Created by Jonathan Karon on 2/20/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NRMATrace;

@interface NRMAThreadLocalStore : NSObject

/** clear the thread's trace stack and frame ptr, and set rootTrace as the 0th item on the stack */
+ (void)setThreadRootTrace:(NRMATrace *)rootTrace;

/** push childTrace onto the thread's stack and set it as the frame ptr. 
    if parentTrace is not on the same thread this will clear the stack and set parentTrace as the 0th item before pushing childTrace. */
+ (BOOL)pushChild:(NRMATrace *)childTrace forParent:(NRMATrace *)parentTrace;

/** if the innermost element on the stack is equal to `trace` remove current trace from stack,
    set parent trace to be active on this thread, and return the parent trace */
+ (BOOL)popCurrentTraceIfEqualTo:(NRMATrace*)trace returningParent:(NRMATrace **)parent;

/** delete thread-local data on all threads */
+ (void)destroyStore;

/** return the currently active trace segment (i.e. frame ptr) for this thread */
+ (NRMATrace*)threadLocalTrace;

@end
