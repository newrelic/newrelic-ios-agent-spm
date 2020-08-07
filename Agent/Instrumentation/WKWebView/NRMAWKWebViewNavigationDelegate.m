//
//  NRMAWKWebViewNavigationDelegate.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/5/17.
//  Copyright © 2017 New Relic. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "NRMAWKWebViewNavigationDelegate.h"

@implementation NRMAWKWebViewNavigationDelegate
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
