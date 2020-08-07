//
//  NRMAMetric.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/19/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAMetric.h"
#import "NRMATraceController.h"
@implementation NRMAMetric

- (instancetype) initWithName:(NSString*)name
              value:(NSNumber*)value
              scope:(NSString*)scope
    produceUnscoped:(BOOL)produceUnscoped
{
    self = [super init];
    if (self) {
        self.name = name;
        self.value = value;
        self.scope = scope;
        self.produceUnscopedMetrics = produceUnscoped;
    }
    return self;
}

- (instancetype) initWithName:(NSString*)name
                        value:(NSNumber *)value
                        scope:(NSString *)scope
{
    return [self initWithName:name
                        value:value
                        scope:scope
              produceUnscoped:YES];
}

@end
