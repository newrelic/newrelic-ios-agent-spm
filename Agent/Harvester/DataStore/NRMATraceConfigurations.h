//
//  NRMATraceConfigurations.h
//  NewRelicAgent
//
//  Created by Jared Stanbrough on 10/10/13.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NRMATraceConfigurations : NSObject
@property(nonatomic,assign) int maxTotalTraceCount;
@property (atomic, strong) NSMutableArray *activityTraceConfigurations;

- (id) initWithArray:(NSArray*)array;
+ (id) defaultTraceConfigurations;

@end
