//
//  NRMeasurement.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/20/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#ifdef __cplusplus
 extern "C" {
#endif

#import <Foundation/Foundation.h>
#import "NRMAMeasurementProtocol.h"
#import "NRMAMeasurementException.h"

@interface NRMAMeasurement : NSObject<NRMAMeasurementProtocol>
{
    NRMAMeasurementType _type;
    NSString* _name;
    BOOL _finished;
}
@property(nonatomic, setter = setEndTime:, getter = endTime) double endTime;
@property(nonatomic, setter = setStartTime:, getter = startTime) double startTime;
@property(strong, nonatomic) NRMAThreadInfo* threadInfo;

- (id) initWithType:(NRMAMeasurementType)_type;

- (NRMAMeasurementType) type;

- (NSString*) name;

- (NRMAThreadInfo*) threadInfo;

- (BOOL) isInstantaneous;

- (void) finish;

- (BOOL) isFinished;

- (double) asDouble;
@end

#ifdef __cplusplus
}
#endif
