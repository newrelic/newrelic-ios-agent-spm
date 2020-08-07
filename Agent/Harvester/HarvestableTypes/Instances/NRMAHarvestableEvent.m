//
// Created by Bryce Buchanan on 2/9/15.
// Copyright (c) 2015 New Relic. All rights reserved.
//

#import "NRMAHarvestableEvent.h"


@implementation NRMAHarvestableEvent
- (instancetype) initWithDictionary:(NSDictionary*)eventDictionary
{
    self = [super init];
    if (self){
        self.event = eventDictionary;
        self.sendAttempts = 0;
    }
    return self;
}

- (id) JSONObject {
    return self.event;
}

@end
