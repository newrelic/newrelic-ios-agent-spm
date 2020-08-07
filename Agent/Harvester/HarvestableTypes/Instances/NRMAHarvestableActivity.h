//
//  NRMAHarvestableActivity.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/12/13.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMATimedTraceSegment.h"

@interface NRMAHarvestableActivity : NRMATimedTraceSegment
- (id) init;
@property(nonatomic,strong) NSMutableArray* childSegments;
@property(nonatomic,assign) NSUInteger sendAttempts;
@property(nonatomic,strong) NSArray* lastActivityStamp;
@end
