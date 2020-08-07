//
//  NRMATraceMachineInstance.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/24/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMATrace.h"
#import "NRMAMeasurementTransmitter.h"
#import "NRMAActivityTrace.h"

@interface NRMATraceMachine : NSObject
{
    //Consumers
    dispatch_queue_t timerQueue;
    NSTimer* healthyTimer;
    NSTimer* unhealthyTimer;
    BOOL _dead;
}

@property(readonly) NSTimeInterval healthyTraceTimeout;
@property(readonly) NSTimeInterval unhealthyTraceTimeout;
@property(atomic,strong) NRMAActivityTrace* activityTrace;
@property(strong,atomic) NSMutableArray* measurementTransmitters;
@property(strong,atomic) NRMAMeasurementPool* tracePool;

- (id) initWithRootTrace:(NRMATrace*)rootTrace;
- (void) invalidateTimers;
@end
