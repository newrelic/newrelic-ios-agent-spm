//
//  NRMAMeasuredActivity.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/22/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAThreadInfo.h"
#import "NRMAMeasurement.h"
#import "NRMAMeasurementPool.h"
@protocol NRMAMeasuredActivityProtocol <NSObject>
- (NSString*) name;
- (NSDate*) startTime;
- (NSDate*) endTime;
- (NRMAThreadInfo*) startingThread;
- (NRMAThreadInfo*) endingThread;
- (BOOL) isAutoInstrumented;
- (NRMAMeasurement*) startingMeasurement;
- (NRMAMeasurement*) endingMeasurement;
- (NRMAMeasurementPool*) measurementPool;
- (void) finish;
- (BOOL) isFinished;
@end
