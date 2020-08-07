//
//  NRMATaskQueue.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/18/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMATaskQueue.h"
#import "NRMAActivityTrace.h"
#import "NRMAActivityTraceMeasurement.h"
#import  "NRMANamedValueMeasurement.h"
#import "NRMAHTTPTransactionMeasurement.h"
#import "NRMAHTTPErrorMeasurement.h"
#include <libkern/OSAtomic.h>
#import "NRMAHarvester.h"
#import "NRMAMethodSummaryMeasurement.h"
#import "NRMAExceptionHandler.h"
#import "NRMAHarvestableHTTPError.h"
#import "NRMAMeasurements.h"
#import "NRMAMetric.h"
#import "NRMAHTTPError.h"
#import "NRMAHTTPTransaction.h"

static double kNRMA_DEQUEUE_PERIOD_SEC = 1;
static __strong NRMATaskQueue* __taskQueue;
@interface NRMATaskQueue ()
@property(atomic) dispatch_source_t timer;
- (void) dequeue;
+ (NRMATaskQueue*) taskQueue;
@end

@interface NRMAMeasurements (private) //methods only used by NRMATaskQueue

+ (void) recordActivityTrace:(NRMAActivityTrace*) activityTrace;

+ (void) recordSummaryMeasurements:(NRMATrace*)trace;

+ (void) recordHTTPError:(NRMAHTTPError*)error;

+ (void) recordMetric:(NRMAMetric*)metric;

+ (void) recordHTTPTransaction:(NRMAHTTPTransaction*)transaction;
@end

@implementation NRMATaskQueue
@synthesize timer;
- (id) init
{
    self = [super init];
    if (self) {
        self.queue = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) dealloc
{
    dispatch_source_cancel(self.timer);
    self.timer = nil;
    self.queue = nil;
}

+ (void) start
{
    dispatch_sync([NRMATaskQueue dispatchQueue], ^{
        NRMATaskQueue* taskQueue = [self new];
        taskQueue.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                                 0,
                                                 0,
                                                 [NRMATaskQueue dispatchQueue]);
        dispatch_source_set_timer(taskQueue.timer,
                                  dispatch_time(DISPATCH_TIME_NOW,
                                                (int64_t)kNRMA_DEQUEUE_PERIOD_SEC * NSEC_PER_SEC),
                                  (int64_t)kNRMA_DEQUEUE_PERIOD_SEC * NSEC_PER_SEC,
                                  (int64_t)kNRMA_DEQUEUE_PERIOD_SEC * NSEC_PER_SEC);
        dispatch_source_set_event_handler(taskQueue.timer, ^{
            [[NRMATaskQueue taskQueue] dequeue];
        });
        dispatch_resume(taskQueue.timer);
        [self setTaskQueue:taskQueue];
    });
}


+ (void) stop
{
    dispatch_sync([NRMATaskQueue dispatchQueue], ^{
        NRMATaskQueue* taskQueue = [self taskQueue];
        if (taskQueue == nil) {
            return;
        }
        [self setTaskQueue:nil];
        
    });
}

+ (void) synchronousDequeue
{
    dispatch_sync([NRMATaskQueue dispatchQueue], ^{
        [[NRMATaskQueue taskQueue] dequeue];
    });
}

+ (void) queue:(id)object
{
    dispatch_async([NRMATaskQueue dispatchQueue],^{
        NSMutableArray* queue = [[self taskQueue] queue];
        [queue addObject:object];
    });
}

- (void) asyncDequeue
{
    dispatch_async([NRMATaskQueue dispatchQueue], ^{
        [self dequeue];
    });
}

#pragma mark - Not Async-Safe
- (void) dequeue
{
    [NRMAMeasurements setBroadcastNewMeasurements:NO];

    while (self.queue.count)
    {
        __strong id object = [self.queue objectAtIndex:0];
        [self.queue removeObjectAtIndex:0];

        @try {
            if ([object isKindOfClass:[NRMAActivityTrace class]]) {
                [NRMAMeasurements recordActivityTrace:object];
                continue;
            }

            if ([object isKindOfClass:[NRMAMetric class]]) {
                [NRMAMeasurements recordMetric:object];
                continue;
            }

            if ([object isKindOfClass:[NRMATrace class]]) { //method trace
                [NRMAMeasurements recordSummaryMeasurements:object];
                continue;
            }
            if ([object isKindOfClass:[NRMAHTTPError class]]) {
                [NRMAMeasurements recordHTTPError:object];
                continue;
            }
            if ([object isKindOfClass:[NRMAHTTPTransaction class]]) {
                [NRMAMeasurements recordHTTPTransaction:object];
                continue;
            }

        } @catch (NSException* exception) {
            [NRMAExceptionHandler logException:exception
                                         class:NSStringFromClass([self class])
                                      selector:NSStringFromSelector(_cmd)];
        }
    }

    [NRMAMeasurements process];
    [NRMAMeasurements setBroadcastNewMeasurements:YES];
}

+ (dispatch_queue_t) dispatchQueue
{
    static dispatch_queue_t __dequeueDispatch;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __dequeueDispatch = dispatch_queue_create("NRMATaskQueueDispatch", DISPATCH_QUEUE_SERIAL);
    });
    return __dequeueDispatch;
}

+ (NRMATaskQueue*) taskQueue
{
    return __taskQueue;
}

+ (void) setTaskQueue:(NRMATaskQueue*)queue {
    NRMATaskQueue* tmp = __taskQueue;
    __taskQueue = queue;
    OSMemoryBarrier();
    tmp = nil;
}
+ (void) clear
{
//test fixture.
    dispatch_sync([NRMATaskQueue dispatchQueue],^{
        NSMutableArray* queue = [self taskQueue].queue;
        [queue removeAllObjects];
    });
}

@end
