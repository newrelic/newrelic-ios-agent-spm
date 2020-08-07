//
//  NRMAHarvestableActivity.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/12/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestableActivity.h"

@implementation NRMAHarvestableActivity
- (id) init{

    self = [super initWithSegmentType:@"Activity"];
    if (self) {
        self.childSegments = [[NSMutableArray alloc] init];
        self.sendAttempts = 0;
    }
    return self;
}

- (id) JSONObject
{
    NSMutableArray* array = [super JSONObject];
    NSMutableArray* subSegments = [[NSMutableArray alloc] init];
    
    [array insertObject:@{@"type": @"ACTIVITY",@"traceVersion":@"1.0"} atIndex:0];

    for (NRMAHarvestableArray* obj in self.childSegments) {
        [subSegments addObject:[obj JSONObject]];
    }

    if ([self.lastActivityStamp count]) {
        [subSegments addObject:self.lastActivityStamp];
    }

    [array addObject:subSegments];
    return array;
}
@end
