//
//  NRHarvestTimer.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/3/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestTimer.h"
#import "NRMAHarvestController.h"
#import "NewRelicInternalUtils.h"
#import "NRMAExceptionHandler.h"
static long long NR_DEFAULT_HARVEST_PERIOD = 60 * 1000; //milliseconds
#define NR_NEVER_TICKED -1

@implementation NRMAHarvestTimer
- (id) initWithHarvester:(NRMAHarvester*)harvester
{
    self = [super init];
    if (self) {
        NRLOG_VERBOSE(@"HarvestTime: %@ initialized", self);
        self.harvester = harvester;
        self.period = NR_DEFAULT_HARVEST_PERIOD;
    }
    return self;
}

- (void) start
{
    if ([self isRunning]) {
        NRLOG_VERBOSE(@"HarvestTimer: Attempting to start while already running.");
        return;
    }
    if (self.period <= 0) {
        NRLOG_ERROR(@"HarvestTimer: Refusing to start with a period of 0 ms");
        return;
    }
    
    NRLOG_INFO(@"HarvestTimer: starting with a period of %lld ms",self.period);
    self.timer = [NSTimer timerWithTimeInterval:((double)self.period) / (double)1000.0
                                           target:self
                                         selector:@selector(harvest)
                                         userInfo:nil
                                          repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
    [self.harvester fireOnHarvestStart];
}

- (void) harvest
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        long long lastTickDelta = [self timeSinceLastTick];
        if  (lastTickDelta < self.period && lastTickDelta != NR_NEVER_TICKED){
            NRLOG_VERBOSE(@"HarvestTimer: Tick is too soon. Skipping.");
            return;
        }
        
        long long startTick = (long long)NRMAMillisecondTimestamp();
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
        @try {
            #endif
            [self tick];
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
        } @catch (NSException *exception) {
            NRLOG_ERROR(@"Harvest tick threw an exception");
            [NRMAExceptionHandler logException:exception class:NSStringFromClass([self class]) selector:@"tick"];
        }
        #endif
        self->lastTick = startTick;
    });
}

- (void) tick
{
    NRLOG_VERBOSE(@"Harvest: Tick");
    long long tick = (long long)NRMAMillisecondTimestamp();
    [self.harvester execute];
    NRLOG_VERBOSE(@"Harvest: executed");
    long long delta = (long long)(NRMAMillisecondTimestamp() - tick);
    NRLOG_VERBOSE(@"HarvestTimer tick took %lld ms",delta);
    [self updateTimer];
}

- (void) updateTimer
{
    if (self.period != ([NRMAHarvestController configuration].data_report_period*1000)) {
        
        [self stop];
        self.period = [NRMAHarvestController configuration].data_report_period*1000;
        NRLOG_VERBOSE(@"Updating harvest period to %lldms",self.period);
        [self start];
    }
}
- (void) stop
{
    if (![self isRunning]) {
        NRLOG_VERBOSE(@"HarvestTimer: attempting to stop when not running.");
        return;
    }
    
    [self.timer invalidate];
}

- (BOOL) isRunning
{
    return self.timer != nil && [self.timer isValid];
}

- (long long) timeSinceLastTick
{
    if (lastTick == 0) return -1;
    return (long long)(NRMAMillisecondTimestamp() - lastTick);
}

- (void) dealloc
{
    NRLOG_VERBOSE(@"HarvestTime: %@ deallocated", self);
    self.harvester = nil;
    _timer = nil;
}
@end
