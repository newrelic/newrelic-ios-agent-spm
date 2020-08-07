//
//  NRMAWebRequestUtil.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 7/19/16.
//  Copyright © 2016 New Relic. All rights reserved.
//

#import "NRMAWebRequestUtil.h"
#import <objc/runtime.h>

#define kNRMA_isWebViewRequestValue @"NRMA__isWebViewRequest"
#define kNRMA_keyValue @"true"
@implementation NRMAWebRequestUtil
+ (BOOL) isWebViewRequest:(NSURLRequest*)request {
    return [request.allHTTPHeaderFields[kNRMA_isWebViewRequestValue] isEqualToString:kNRMA_keyValue];
}

+ (NSMutableURLRequest*) setIsWebViewRequest:(NSURLRequest*)request {
    if (request != nil) {
        NSMutableURLRequest* mutableRequest = [request mutableCopy];
        [mutableRequest setValue:kNRMA_keyValue forHTTPHeaderField:kNRMA_isWebViewRequestValue];
        return mutableRequest;
    }
    return nil;
}

+ (NSMutableURLRequest*) clearIsWebViewRequest:(NSURLRequest*)request {
    if (request != nil) {
        NSMutableURLRequest* mutableRequest = [request mutableCopy];
        [mutableRequest setValue:nil forHTTPHeaderField:kNRMA_isWebViewRequestValue];
        return mutableRequest;
    }
    return nil;
}
@end
