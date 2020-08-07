//
//  NRMARetryTracker.m
//  NewRelic
//
//  Created by Bryce Buchanan on 7/25/17.
//  Copyright (c) 2017 New Relic. All rights reserved.
//

#import "NRMARetryTracker.h"

@interface NRMARetryTracker ()

@property(strong,atomic)NSMutableDictionary* tasks;
@property(readonly) int retryLimit;
@end


@implementation NRMARetryTracker

- (instancetype) initWithRetryLimit:(unsigned int)retries {
    self = [super init];
    if (self) {
        self.tasks = [[NSMutableDictionary alloc] init];
        _retryLimit = retries;
    }
    return self;
}


- (void) track:(__nonnull id<NSCopying>)object {
    if(object==nil) return;
    @synchronized(self.tasks) {
        [self.tasks setObject:@(0)
                      forKey:object];
    }
}

- (void) untrack:(__nonnull id<NSCopying>)object {
    if(object==nil) return;
    @synchronized(self.tasks) {
        [self.tasks removeObjectForKey:object];
    }
}

- (BOOL) shouldRetryTask:(__nonnull id<NSCopying>)object {
    if(object==nil) return NO;
    @synchronized(self.tasks) {
        if (!self.tasks[object]) return NO;
        self.tasks[object] = @([self.tasks[object] integerValue] + 1);
        return [self.tasks[object] integerValue] <= self.retryLimit;

    }
}

@end
