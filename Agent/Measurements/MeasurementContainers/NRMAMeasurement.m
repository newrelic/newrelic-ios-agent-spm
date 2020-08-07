//
//  NRMAMeasurement.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/20/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMeasurement.h"

@implementation NRMAMeasurement
@synthesize endTime, startTime;
- (id) initWithType:(NRMAMeasurementType)type
{
    
    if (type == NRMAMT_Any) {
        @throw [NRMAMeasurementException exceptionWithName:NRMAMeasurementTypeConsistencyError
                                                    reason:@"A measurement cannot have type:Any" userInfo:nil];
    }
    self = [super init];
    if (self) {
        self.type = type;
        startTime = 0;
        endTime = 0;
    }
    return self;
}

- (void) setType:(NRMAMeasurementType)type
{
    [self throwIfFinished];
    _type = type;
}

- (void) setName:(NSString*)name {
    _name = name;
}
- (void) setStartTime:(double)_startTime
{
    [self throwIfFinished];
    startTime = _startTime;
}
- (void) setEndTime:(double)_endTime
{
    [self throwIfFinished];
    if (_endTime < startTime) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Measurement end time must not precede start time."
                                     userInfo:nil];
    }
    endTime = _endTime;
}

- (void) throwIfFinished
{
    if (_finished) {
        @throw [[NRMAMeasurementException alloc] initWithName:NRMAFinishedMeasurementEditedException
                                                     reason:@"Attempted to modify finished measurement."
                                                   userInfo:nil];
    }
}

- (NRMAMeasurementType) type
{
    return _type;
}

- (NSString*) name
{
    return _name;
}

- (double) startTime
{
    return startTime;
}

- (double) endTime
{
    return endTime;
}


- (BOOL) isInstantaneous
{
    return endTime == 0;
}

- (void) finish
{
    if (_finished) {
        //throw an exception
        @throw [NRMAMeasurementException exceptionWithName:NRMAFinishedMeasurementEditedException
                                                  reason:@"Finish called on already finished Measurement"
                                                userInfo:nil];
    }
    _finished = YES;
}

- (BOOL) isFinished
{
    return _finished;
}

- (double) asDouble
{
    //unsupported
    @throw nil;
}

@end
