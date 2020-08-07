//
//  NRMAURLSessionDelegate.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 3/20/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAURLSessionTaskDelegate.h"

@implementation NRMAURLSessionTaskDelegate


- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([self.realDelegate respondsToSelector:aSelector]){
        return YES;
    }
    return [super respondsToSelector:aSelector];
}
    
- (BOOL) isKindOfClass:(Class)aClass {
    return self.class == aClass || [super isKindOfClass:aClass] || [self.realDelegate isKindOfClass:aClass];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return self.realDelegate;
}

@end
