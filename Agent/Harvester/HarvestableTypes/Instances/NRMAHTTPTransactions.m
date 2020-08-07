//
//  NRMAHTTPTransactions.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/4/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHTTPTransactions.h"
#import "NRMAHarvestableHTTPTransaction.h"
#import "NRMAMeasurements.h"
#import "NRMAExceptionHandler.h"
#import "NRMAHarvestController.h"
#import "NRMATaskQueue.h"
#import "NRMAMetric.h"
@implementation NRMAHTTPTransactions
- (id) init
{
    self = [super init];
    if (self) {
        httpTransactions = [[NSMutableArray alloc] init];
    }
    return self;
}
- (void) add:(NRMAHarvestableHTTPTransaction*)transaction
{
    
    if (transaction.errorCode != 0 && ![NRMAHarvestController configuration].collect_network_errors) {
        NRLOG_VERBOSE(@"Network error ignored. collect_network_errors disabled.");
        return;
    }
    
    @synchronized(httpTransactions)
    {
        if (httpTransactions.count >= [NRMAHarvestController configuration].report_max_transaction_count) {
            NRLOG_VERBOSE(@"Max transaction count reached: %d",[NRMAHarvestController configuration].report_max_transaction_count);
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
            @try {
                #endif
                [NRMATaskQueue queue:[[NRMAMetric alloc] initWithName:kNRSupportabilityPrefix@"/TransactionsDropped"
                                       value:@1
                                   scope:@""]];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
            } @catch (NSException* exception) {
                [NRMAExceptionHandler logException:exception
                                           class:NSStringFromClass([self class])
                                        selector:NSStringFromSelector(_cmd)];
            }
            #endif
            return;
        }
        [httpTransactions addObject:transaction];
    }
}
- (id)JSONObject
{
    @synchronized(httpTransactions) {
        NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity:[httpTransactions count]];
        for (NRMAHarvestableHTTPTransaction* transaction in httpTransactions) {
            [array addObject:[transaction JSONObject]];
        }
        return array;
    }
}

- (void) clear
{
    @synchronized(httpTransactions) {
        [httpTransactions removeAllObjects];
    }
}


- (void) removeObjectsWithAge:(NSTimeInterval)ageSeconds
{
    NSMutableArray* removalList = [[NSMutableArray alloc] init];
    double currentTimeSeconds = [[NSDate date] timeIntervalSince1970];
    @synchronized (httpTransactions) {
        for (NRMAHarvestableHTTPTransaction* transaction in httpTransactions) {
            if ((transaction.startTimeSeconds + transaction.totalTimeSeconds) + ageSeconds < currentTimeSeconds) {
                [removalList addObject:transaction];
            }
        }
        
        [httpTransactions removeObjectsInArray:removalList];
    }
}

#pragma mark NRMAHarvestAware Methods

- (void) onHarvestBefore
{
    //remove old garbage.
    //maybe add them to transactions dropped?
    [self removeObjectsWithAge:[NRMAHarvestController configuration].report_max_transaction_age];
}

@end
