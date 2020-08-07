//
//  NRMADEBUG_Reachability.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 12/11/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMADEBUG_Reachability.h"

#ifdef NRMA_REACHABILITY_DEBUG
@implementation NRMADEBUG_Reachability

static NSString* cacheHitLock;
- (void) syncIncCacheHit {
    @synchronized(cacheHitLock ) {
        self.cacheHit++;
    }
}
static NSString* waitLock;
- (void) syncIncWaited {
    @synchronized(waitLock) {
        self.waited++;
    }
}

static NSString* reachHitLock;
- (void) syncIncReachabilityHit {
    @synchronized(reachHitLock) {
        self.reachabilityHit++;
    }
}

static NSString* totalLock;
- (void) syncIncTotal
{
    @synchronized(totalLock) {
        self.total ++;
    }
}

static NSString* noWaitLock;
- (void) syncIncNoWait {
    @synchronized(noWaitLock) {
        self.noWait ++;
    }
}

static NSString* nwchLock;
- (void) addNoWaitingCacheHitWait:(double)millis {
    @synchronized(nwchLock) {
        self.noWaitingCacheHitAggWait += millis;
    }
}
static NSString* wchLock;
- (void) addWaitingCacheHitWait:(double)millis {
    @synchronized(wchLock) {
        self.waitingCacheHitAggWait += millis;
    }

}
static NSString* reachwaitlock;
- (void) addReachabilityWait:(double)millis {
    @synchronized(reachHitLock) {
        self.reachabilityAggWait += millis;
    }

}

- (NSString*) description {
    return [NSString stringWithFormat:@"totalcount: %d cacheHitWithWait: %d (%f) cacheHitWithNoWait: %d (%f) TtlCacheHits:%d reachabilityRequests: %d (%f)", self.total, self.waited,
            self.waitingCacheHitAggWait / self.waited,
            self.noWait, self.noWaitingCacheHitAggWait / self.noWait,
            self.cacheHit, self.reachabilityHit, self.reachabilityAggWait / self.reachabilityHit];
}
@end
#endif
