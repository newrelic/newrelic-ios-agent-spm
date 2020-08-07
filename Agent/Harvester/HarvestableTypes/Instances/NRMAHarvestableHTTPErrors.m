//
//  NNRMAHarvestableHTTPErrors.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/27/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestableHTTPErrors.h"
#import "NRMAHarvestController.h"
#import "NRMAExceptionHandler.h"
#import "NRMAMeasurements.h"
#import "NRMATaskQueue.h"
#import "NRMAMetric.h"
@implementation NRMAHarvestableHTTPErrors
- (id) init
{
    self = [super init];
    if (self) {
        httpErrors = [[NSMutableDictionary alloc] init];
    }
    return self;
}
	

- (void) addHTTPError:(NRMAHarvestableHTTPError*)error
{
    if (! error) {
        NRLOG_WARNING(@"Ignoring addHTTPError: call w/ nil value");
        return;
    }
    
    @synchronized(httpErrors) {
        NRMAHarvestableHTTPError* existingError = [httpErrors objectForKey:error.digest];
        if (existingError) {
            existingError.count++;
            return;
        }
        
        if (httpErrors.count >= [NRMAHarvestController configuration].error_limit) {
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
            @try {
                #endif
                [NRMATaskQueue queue:[[NRMAMetric alloc] initWithName:kNRSupportabilityPrefix@"/Collector/ErrorsDropped"
                                       value:@1
                                   scope:@""]];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
            } @catch (NSException* exception) {
                [NRMAExceptionHandler logException:exception
                                           class:NSStringFromClass([self class])
                                        selector:NSStringFromSelector(_cmd)];
            }
#endif
            NRLOG_VERBOSE(@"Server error limit of %d reached. Ignoring error.", [NRMAHarvestController configuration].error_limit );
            return;
        }
        [httpErrors setObject:error forKey:error.digest];
    }
}

- (id) JSONObject
{
    @synchronized(httpErrors) {
        NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity:httpErrors.count];
        for (NSString* key in [httpErrors allKeys]) {
            [array addObject:[[httpErrors objectForKey:key] JSONObject]];
        }
        return array;
    }
}

- (void) clear
{
    @synchronized(httpErrors) {
        [httpErrors removeAllObjects];
    }
}


- (void) removeObjectWithAge:(NSTimeInterval)ageSeconds
{
    @synchronized(httpErrors){
        NSTimeInterval currentTimeSeconds =  [[NSDate date] timeIntervalSince1970];
        NSMutableArray* removalArray = [[NSMutableArray alloc] init];
        for (NSString* key in [httpErrors allKeys]) {
            NRMAHarvestableHTTPError* error = [httpErrors objectForKey:key];
            if (error.startTimeSeconds + ageSeconds < currentTimeSeconds) {
                [removalArray addObject:key];
            }
        }
        [httpErrors removeObjectsForKeys:removalArray];
    }
}

#pragma mark - NRMAHarvestAware Methods

- (void) onHarvestBefore
{
    //remove old items
    [self removeObjectWithAge:[NRMAHarvestController configuration].report_max_transaction_age];
}
@end
