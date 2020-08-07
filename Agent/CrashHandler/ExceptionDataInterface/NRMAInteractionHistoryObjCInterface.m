//
//  NRMAInteractionHistoryObjCInterface.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/19/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAInteractionHistoryObjCInterface.h"
#import "NRMAInteractionHistory.h"
@implementation NRMAInteractionHistoryObjCInterface


static const NSString* kNRMAIteractionLock = @"interactionLock";
+ (void) insertInteraction:(NSString*)name startTime:(long long)epochMillis
{
    @synchronized (kNRMAIteractionLock){
        NRMA__AddInteraction(name.UTF8String, epochMillis);
    }
}

+ (void) deallocInteractionHistory
{
    @synchronized(kNRMAIteractionLock) {
        NRMA__deallocInteractionHistoryList();
    }
}
@end
