//
//  NRMATimedTraceSegment.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/1/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMATraceSegment.h"

@interface NRMATimedTraceSegment : NRMATraceSegment
@property(nonatomic,assign) long long startTime;
@property(nonatomic,assign) long long endTime;
@property(nonatomic,strong) NSString* name;
@end
