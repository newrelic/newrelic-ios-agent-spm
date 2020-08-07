//
//  NRMAHarvestableVitals.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/14/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestableVitals.h"

@implementation NRMAHarvestableVitals
- (id) initWithCPUVitals:(NSDictionary*)cpu
            memoryVitals:(NSDictionary*)memory
{
    self = [super initWithSegmentType:@"VITALS"];
    if (self) {
        self.cpuVitals = cpu;
        self.memoryVitals = memory;
    }
    return self;
}

- (id) JSONObject
{
    NSMutableArray* jsonArray = [[NSMutableArray alloc] init];
    [jsonArray addObject:@{@"type":self.segmentType}];
    [jsonArray addObject:@{@"CPU":[self dictionaryToTuple:self.cpuVitals],@"MEMORY":[self dictionaryToTuple:self.memoryVitals]}];
    return jsonArray;
}

- (NSArray*) dictionaryToTuple:(NSDictionary*)dictionary
{
    NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity:dictionary.count];
    for (id obj in dictionary.allKeys) {
        [array addObject:@[obj,[dictionary objectForKey:obj]]];
    }
    return array;
}

@end
