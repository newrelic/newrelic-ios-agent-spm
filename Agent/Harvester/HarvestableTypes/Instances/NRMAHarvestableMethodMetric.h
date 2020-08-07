//
//  NRMAHarvestableMethodMetric.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/8/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestableMetric.h"

@interface NRMAHarvestableMethodMetric : NRMAHarvestableMetric
@property(nonatomic,strong) NSMutableArray* exclusiveTimes;
- (void) addExclusiveTime:(NSNumber*)value;
@end
