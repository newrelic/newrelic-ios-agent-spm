//
// Created by Bryce Buchanan on 2/9/15.
// Copyright (c) 2015 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAHarvestableValue.h"

@interface NRMAHarvestableEvent : NRMAHarvestableValue
@property(strong) NSDictionary* event;
@property(atomic) unsigned int sendAttempts;
- (instancetype) initWithDictionary:(NSDictionary*)eventDictionary;
@end
