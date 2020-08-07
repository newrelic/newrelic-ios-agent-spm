//
//  NRMAEnvironmentTraceSegment.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/1/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAEnvironmentTraceSegment.h"
#import "NRMAAgentConfiguration.h"
@implementation NRMAEnvironmentTraceSegment

- (instancetype) init {
    self = [super initWithSegmentType:@"environment"];
    if (self) {
        
    }
    return self;
}

- (id) JSONObject
{
    NSMutableArray* array = [super JSONObject];
    [array insertObject:@{@"type": @"ENVIRONMENT"   }
                atIndex:0];
    return [array arrayByAddingObjectsFromArray:[[NRMAAgentConfiguration connectionInformation] JSONObject]];
    

}
@end
