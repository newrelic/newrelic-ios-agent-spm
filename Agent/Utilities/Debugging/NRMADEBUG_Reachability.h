//
//  NRMADEBUG_Reachability.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 12/11/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifdef NRMA_REACHABILITY_DEBUG
@interface NRMADEBUG_Reachability : NSObject

@property(atomic) int cacheHit;
@property(atomic) int noWait;
@property(atomic) int waited;
@property(atomic) int reachabilityHit;
@property(atomic) int total;


@property(atomic) double noWaitingCacheHitAggWait;
@property(atomic) double waitingCacheHitAggWait;
@property(atomic) double reachabilityAggWait;

- (void) syncIncTotal;
- (void) syncIncCacheHit;
- (void) syncIncWaited;
- (void) syncIncNoWait;
- (void) syncIncReachabilityHit;

- (void) addNoWaitingCacheHitWait:(double)millis;
- (void) addWaitingCacheHitWait:(double)millis;
- (void) addReachabilityWait:(double)millis;

- (NSString*) description;

@end
#endif
