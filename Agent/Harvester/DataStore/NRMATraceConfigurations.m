//
//  NRMATraceConfigurations.m
//  NewRelicAgent
//
//  Created by Jared Stanbrough on 10/10/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMATraceConfigurations.h"
#import "NRMATraceConfiguration.h"

@implementation NRMATraceConfigurations

- (id) initWithArray:(NSArray*)array
{
    self = [super init];
    if (self) {
        if (array != nil && array.count == 2) {
            self.maxTotalTraceCount = [[array objectAtIndex:0] intValue];
            NSArray *configurations = [array objectAtIndex:1];

            self.activityTraceConfigurations = [[NSMutableArray alloc] initWithCapacity:configurations.count];

            for (int configurationIndex = 0; configurationIndex < configurations.count; configurationIndex++) {
                NSArray* configArray = [configurations objectAtIndex:configurationIndex];
                NRMATraceConfiguration *configuration = [[NRMATraceConfiguration alloc] init];

                // Set the name and total count
                configuration.activityTraceNamePattern = [configArray objectAtIndex:0];
                configuration.totalTraceCount = [[configArray objectAtIndex:1] intValue];

                [self.activityTraceConfigurations addObject:configuration];
            }
        }
    }
    return self;
}
+ (id) defaultTraceConfigurations
{
    NRMATraceConfigurations* traceConfigurations = [[NRMATraceConfigurations alloc] init];
    traceConfigurations.maxTotalTraceCount = 1;
    return traceConfigurations;
}
@end
