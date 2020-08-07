//
//  NRMATimestampContainer.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/18/17.
//  Copyright © 2017 New Relic. All rights reserved.
//

#import "NRMATimestampContainer.h"
#import "NRConstants.h"





@implementation NRMATimestampContainer
- (instancetype) initWithTimestamp:(double)timestamp {
    if (self = [super init]) {
        self.units = [NRMATimestampContainer findUnits:timestamp];
        self.timestamp = timestamp;
    }
    return self;
}

- (instancetype) initWithTimestamp:(double)timestamp units:(NRMATimeUnit)units {
    if (self = [super init]){
        self.units = units;
        self.timestamp = timestamp;
    }
    return self;
}


+ (NRMATimeUnit) findUnits:(double)timestamp {
    if(timestamp == 0) return NRMATU_UNKWN;
    NSTimeInterval epoch = [[NSDate new] timeIntervalSince1970];

    // - calculate the order of magnitude of a second timestamp and compare it
    //   with the incoming timestamp (which has unknown units)
    // - fabs it to ensure positive value
    // - round it to the nearest integer (it wont be exactly round)
    // - 1 or 2 difference... decisecond, kilisecond, wtf?
    // - 3 means the unknown timestamp is in milliseconds
    // - 0 means the unknown timestamp is in seconds

    int orderOfMagnitudeDifference = (int)round(fabs(log10(epoch) - (log10(timestamp))));
    switch (orderOfMagnitudeDifference) {
        case 0:
            return NRMATU_SEC;
        case 3:
            return NRMATU_MILLI;
        default:
            return NRMATU_UNKWN;
    }
}

- (double) toSeconds {
    switch (self.units) {
        case NRMATU_SEC:
            return self.timestamp;
        case NRMATU_MILLI: {
            return (double)self.timestamp * (double)kNRMASecondsPerMillisecond;
        }
        default:
            return -1;
    }
}
- (double) toMilliseconds {
    switch (self.units) {
        case NRMATU_SEC:
            return (double)self.timestamp / (double)kNRMASecondsPerMillisecond;
        case NRMATU_MILLI:
            return self.timestamp;
        default:
            return -1;
    }
}


@end
