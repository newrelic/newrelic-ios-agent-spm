//
//  NRMANSURLConnectionDelegate.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/23/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMANSURLConnectionDelegate.h"

@protocol NSURLConnectionDataDelegate;
@protocol NSURLConnectionDownloadDelegate;

@implementation NRMANSURLConnectionDelegate

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([self.realDelegate respondsToSelector:aSelector])
        return YES;

    // implementing stuff from NSURLConnectionDownloadDelegate causes the NSURLConnection
    //  to send NSURLConnectionDownloadDelegate events INSTEAD OF NSURLConnectionDataDelegate events
    // so don't say we implement NSURLConnectionDownloadDelegate unless the real delegate does
    if (aSelector == @selector(connection:didWriteData:totalBytesWritten:expectedTotalBytes:)
        || aSelector == @selector(connectionDidFinishDownloading:destinationURL:)) {
        return NO;
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
