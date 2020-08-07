//
//  NRMACPUVitals.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/7/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef struct {
    double utime, stime;
} CPUTime;

@interface NRMACPUVitals : NSObject

+ (int) appStartCPUtime:(CPUTime*)cpuTime;

+ (int) setAppStartCPUTime;

+ (int)cpuTime:(CPUTime*) time;
@end
