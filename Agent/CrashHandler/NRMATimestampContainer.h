//
//  NRMATimestampContainer.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/18/17.
//  Copyright © 2017 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NRMATimeUnit) {
    NRMATU_UNKWN = 0,
    NRMATU_SEC,
    NRMATU_MILLI
};


@interface NRMATimestampContainer : NSObject
@property(assign) NRMATimeUnit units;
@property(assign) double timestamp;

//this constructor assumes the timestamp parameter is relatively close to
//the current date, using order of magnitude to determine if it is seconds or
//milliseconds.
- (instancetype) initWithTimestamp:(double)timestamp;

//use this constructor to manually set the units.
- (instancetype) initWithTimestamp:(double)timestamp units:(NRMATimeUnit)units;

- (double) toSeconds;
- (double) toMilliseconds;

//this method assumes the timestamp parameter is relatively close to
//the current date, using order of magnitude to determine if it is seconds or
//milliseconds.
+ (NRMATimeUnit) findUnits:(double)timestamp;
@end
