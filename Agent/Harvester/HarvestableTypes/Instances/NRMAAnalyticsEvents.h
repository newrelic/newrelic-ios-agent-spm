//
// Created by Bryce Buchanan on 2/9/15.
// Copyright (c) 2015 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAHarvestableArray.h"
#import "NRMAHarvestAware.h"

@interface NRMAAnalyticsEvents :  NRMAHarvestableArray <NRMAHarvestAware>
@property(atomic,retain) NSMutableArray* events;
- (void) clear;
- (NSUInteger) count;
- (void) addEvents:(NSArray*) events; // array of dictionaries
@end
