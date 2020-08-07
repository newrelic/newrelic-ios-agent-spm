//
//  NRMAMetric.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/19/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NRMAMetric : NSObject
@property(strong) NSString* name;
@property(strong) NSNumber* value;
@property(strong) NSString* scope;
@property(assign) BOOL produceUnscopedMetrics;

- (instancetype) initWithName:(NSString*)name
                        value:(NSNumber*)value
                        scope:(NSString*)scope
              produceUnscoped:(BOOL)produceUnscoped;

- (instancetype) initWithName:(NSString*)name
                        value:(NSNumber*)value
                        scope:(NSString*)scope;
@end
