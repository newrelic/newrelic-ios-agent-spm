//
//  Timer.m
//  NewRelicAgent
//
//  Created by Saxon D'Aubin on 5/24/12.
//  Copyright (c) 2012 New Relic. All rights reserved.
//

#import <mach/mach.h>
#import <mach/mach_time.h>

#import "NewRelicInternalUtils.h"
#import "NRTimer.h"
#import "NRLogger.h"
// Macro to give us an efficient one-time function call.
// The token trickiness is from here:
// http://bit.ly/fQ6Glh
#define TokenPasteInternal(x,y) x ## y
#define TokenPaste(x,y) TokenPasteInternal(x,y)
#define UniqueTokenMacro TokenPaste(unique,__LINE__)
#define OneTimeCall(x) \
{ static BOOL UniqueTokenMacro = NO; \
if (!UniqueTokenMacro) {x; UniqueTokenMacro = YES; }}


double NRMA_timeElapsedInSeconds(double t_start, double t_end);
double NRMA_timeElapsedInMilliSeconds(double t_start, double t_end);


static struct mach_timebase_info nr_timebase_info;

// from https://github.com/tylerneylon/moriarty/blob/master/CodeTimestamps.m
double NRMA_NanosecondsFromTimeInterval(double timeInterval) {
    OneTimeCall(mach_timebase_info(&nr_timebase_info));
    timeInterval *= nr_timebase_info.numer;
    timeInterval /= nr_timebase_info.denom;
    return timeInterval;
}

//
// Static methods
double NRMA_timeElapsedInSeconds(double t_start, double t_end)
{
    return (double)(t_end - t_start)/1000;
}

double NRMA_timeElapsedInMilliSeconds(double t_start, double t_end) {
    return t_end - t_start;
}

double NRMA_timeInMillis(double time) {
    return time;
}


@implementation NRTimer

@synthesize endTimeMillis = _endTimeMillis;
@synthesize startTimeMillis = _startTimeMillis;

-(id) init
{
    self = [super init];
    if (self) {
        [self restartTimer];

    }
    return self;
}

- (void) restartTimer
{
    self->_startTimeMillis = NRMAMillisecondTimestamp();
    self->_endTimeMillis = 0;
    
}

- (void) stopTimer {
    if (self->_endTimeMillis == 0) {
        self->_endTimeMillis = NRMAMillisecondTimestamp();
    }
}

- (BOOL)hasRunAndFinished {
    return (self->_startTimeMillis != 0 && self->_endTimeMillis >= self->_startTimeMillis);
}

- (double) timeElapsedInSeconds {
    if (self->_startTimeMillis <= 0) {
        NRLOG_WARNING(@"NRMATimer does not have a valid start time: %lf", self->_startTimeMillis);
        return 0;
    }
    if (self->_endTimeMillis < self->_startTimeMillis) {
        NRLOG_VERBOSE(@"NRMATimer has a negative duration: %lf => %lf", self->_startTimeMillis, self->_endTimeMillis);
        return 0;
    }
    return NRMA_timeElapsedInSeconds(self->_startTimeMillis, self->_endTimeMillis);
}

- (double) timeElapsedInMilliSeconds {
    if (self->_startTimeMillis <= 0) {
        NRLOG_WARNING(@"NRMATimer does not have a valid start time: %lf", self->_startTimeMillis);
        return 0;
    }
    if (self->_endTimeMillis < self->_startTimeMillis) {
        NRLOG_VERBOSE(@"NRMATimer has a negative duration: %lf => %lf", self->_startTimeMillis, self->_endTimeMillis);
        return 0;
    }
    return NRMA_timeElapsedInMilliSeconds(self->_startTimeMillis, self->_endTimeMillis);
}

- (double) startTimeInMillis {
    if (self->_startTimeMillis <= 0) {
        NRLOG_WARNING(@"NRMATimer does not have a valid start time: %lf", self->_startTimeMillis);
        return 0;
    }
    return NRMA_timeInMillis(self->_startTimeMillis);
}

- (double) endTimeInMillis {
    if (self->_endTimeMillis <= 0) {
        NRLOG_WARNING(@"NRMATimer does not have a valid end time: %lf", self->_endTimeMillis);
        return 0;
    }
    return NRMA_timeInMillis(self->_endTimeMillis);
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"Elapsed time: %f", [self timeElapsedInSeconds]];
}

@end
