//
//  NRMATraceMachineInstance.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/24/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMATraceMachine.h"
#import "NRMATraceController.h"
#import "NRMAExceptionHandler.h"
#import "NewRelicInternalUtils.h"
#import "NRMATaskQueue.h"
#import "NRMAMeasurements.h"
#import "NRMALastActivityTraceController.h"

@implementation NRMATraceMachine
static NSString *cleanupLock = @"cleanup lock";
- (void) cleanup
{
    @synchronized(cleanupLock) {
        if (self->_dead)
            return;

        self->_dead = YES;

        [NRMAThreadInfo clearThreadNames];
        [self invalidateTimers];
        timerQueue = nil;
        self.measurementTransmitters = nil;
    }
}

- (void) invalidateTimers
{
    @synchronized(self) {
        [self invalidateHealthyTimer];
        [self invalidateUnhealthyTimer];
    }
}


static NSString *unhealthyTimerLock = @"unhealthy timer lock";
- (void) invalidateUnhealthyTimer
{
    @synchronized(unhealthyTimerLock) {
        if (self->_dead)
            return;

        dispatch_sync(timerQueue, ^{
            [self->unhealthyTimer invalidate];
            //            assert(!unhealthyTimer.isValid);
            self->unhealthyTimer = nil;
        });
    }
}

static NSString *healthyTimerLock = @"healthy timer lock";
- (void) invalidateHealthyTimer
{
    @synchronized(healthyTimerLock) {
        if (self->_dead)
            return;

        dispatch_sync(timerQueue, ^{
            [self->healthyTimer invalidate];
            //            assert(!healthyTimer.isValid);
            self->healthyTimer = nil;
        });
    }
}

- (void) startUnhealthyTimerWithInterval:(NSTimeInterval)interval
{
    dispatch_sync(timerQueue,^{
        self->unhealthyTimer = [NSTimer timerWithTimeInterval:interval
                                                       target:self
                                                     selector:@selector(unhealthyTimeout)
                                                     userInfo:nil
                                                      repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self->unhealthyTimer forMode:NSDefaultRunLoopMode];
    });
}

- (void) startHealthyTimerWithInterval:(NSTimeInterval)interval
{
    dispatch_sync(timerQueue, ^{
        self->healthyTimer = [NSTimer timerWithTimeInterval:interval
                                                     target:self
                                                   selector:@selector(healthyTimeout)
                                                   userInfo:nil
                                                    repeats:NO];
        NRLOG_VERBOSE(@"Healthy trace timer started with interval: %f",interval);
        [[NSRunLoop mainRunLoop] addTimer:self->healthyTimer forMode:NSDefaultRunLoopMode];
    });
}

- (void) healthyTimeout
{
    NRLOG_VERBOSE(@"Healthy trace timer fired");
    double currentTime = NRMAMillisecondTimestamp();
    double lastUpdated = self.activityTrace.lastUpdated;

    NSTimeInterval timeSinceLastUpdate = (currentTime - lastUpdated) + .001;
    NSTimeInterval healthyTimeoutMillis = self.healthyTraceTimeout * 1000;
    if(timeSinceLastUpdate < healthyTimeoutMillis) {
        [self invalidateHealthyTimer];
        NSTimeInterval timeLeftSeconds = (healthyTimeoutMillis - timeSinceLastUpdate)/1000;
        if (timeLeftSeconds <= 0) {
            timeLeftSeconds = self.healthyTraceTimeout;
        }
        [self startHealthyTimerWithInterval:timeLeftSeconds];
        return;
    }

    if(![self.activityTrace hasMissingChildren]) {
        [NRMATraceController completeActivityTrace];
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
        @try {
#endif
            [NRMATaskQueue queue:[[NRMAMetric alloc] initWithName:kNRSupportabilityPrefix@"/HealthyActivityTraces"
                                                            value:@1
                                                            scope:@""]];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
        } @catch (NSException* exception) {
            [NRMAExceptionHandler logException:exception
                                         class:NSStringFromClass([self class])
                                      selector:NSStringFromSelector(_cmd)];
        }
#endif
        return;
    }
    [self invalidateHealthyTimer];
    [self startHealthyTimerWithInterval:self.healthyTraceTimeout];
}

- (void) unhealthyTimeout
{
    NRLOG_VERBOSE(@"Unhealthy trace timer fired");
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif


        [NRMATaskQueue queue:[[NRMAMetric alloc] initWithName:kNRSupportabilityPrefix@"/UnhealthyActivityTraces"
                                                        value:@1
                                                        scope:@""]];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                     class:NSStringFromClass([self class])
                                  selector:NSStringFromSelector(_cmd)];
    }
#endif
    [NRMATraceController completeActivityTrace];
}
- (void) dealloc
{
    [self.tracePool shutdown];
    self.tracePool = nil;
    [self cleanup];
}

- (id) initWithRootTrace:(NRMATrace*)rootTrace
{
    self = [super init];
    if (self) {
        self.measurementTransmitters = [[NSMutableArray alloc] init];
        self.tracePool = [[NRMAMeasurementPool alloc] init];
        [self setupTracePool];
        timerQueue = dispatch_queue_create("timerQueue", NULL);
        self.activityTrace = [[NRMAActivityTrace alloc] initWithRootTrace:rootTrace];
        self.activityTrace.lastActivityStamp = [NRMALastActivityTraceController copyLastActivityStamp];
        //we want to be able to change the tracetimeouts, but we don't want
        //them to change in mid-trace
        _healthyTraceTimeout = [NRMATraceController healthyTraceTimeout];
        _unhealthyTraceTimeout = [NRMATraceController unhealthyTraceTimeout];
        [self startTimers];
    }
    return self;
}

- (void) startTimers
{
    [self startUnhealthyTimerWithInterval:self.unhealthyTraceTimeout];
    [self startHealthyTimerWithInterval:self.healthyTraceTimeout];

}

- (void) setupTracePool
{
    @synchronized(self.measurementTransmitters) {

        //add http error producer
        NRMAMeasurementTransmitter* networkTransmitter = [[NRMAMeasurementTransmitter alloc] initWithType:NRMAMT_Network
                                                                                          destinationPool:self.tracePool];
        [self.measurementTransmitters addObject:networkTransmitter];
        [NRMAMeasurements addMeasurementConsumer:networkTransmitter];

        //add http transaction producer
        NRMAMeasurementTransmitter* httpTransmitter = [[NRMAMeasurementTransmitter alloc] initWithType:NRMAMT_HTTPTransaction
                                                                                       destinationPool:self.tracePool];
        [self.measurementTransmitters addObject:httpTransmitter];
        [NRMAMeasurements addMeasurementConsumer:httpTransmitter];

        //add Event producer
        NRMAMeasurementTransmitter* eventTransmitter = [[NRMAMeasurementTransmitter alloc] initWithType:NRMAMT_NamedEvent
                                                                                        destinationPool:self.tracePool];
        [self.measurementTransmitters addObject:eventTransmitter];
        [NRMAMeasurements addMeasurementConsumer:eventTransmitter];
    }

}

@end
