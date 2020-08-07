//
//  NRMANamedValueMeasurement.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/30/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMANamedValueMeasurement.h"
#import "NewRelicInternalUtils.h"
@implementation NRMANamedValueMeasurement
- (instancetype) initWithName:(NSString*)name
                        value:(NSNumber*)value
{
    self = [super initWithType:NRMAMT_NamedValue];
    if (self) {
        _name = name;
        _value = value;
        self.startTime = NRMAMillisecondTimestamp();
        self.endTime = self.startTime;
    }
    return self;
}
@end
