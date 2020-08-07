//
//  NRMAActivityTraceMeasurement.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/11/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAActivityTraceMeasurement.h"

@implementation NRMAActivityTraceMeasurement

- (id) initWithActivityTrace:(NRMAActivityTrace*)trace
{
    self = [super initWithType:NRMAMT_Activity];
    if (self) {
        self.traceName = trace.name;
       self.endTime   = trace.endTime; 
        self.startTime = trace.startTime;
        
        self.rootTrace = trace.rootTrace;
        self.lastActivity = trace.lastActivityStamp;
        self.cpuVitals = trace.cpuVitals;
        self.memoryVitals = trace.memoryVitals;
    }
    return self;
}


@end
