//
//  NRMAHTTPTransactions.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/4/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestableArray.h"
#import "NRMAHarvestableHTTPTransaction.h"
#import "NRMAHarvestAware.h"

#define kNRMAStoreHTTPTransactionNotification @"com.newrelic.storeHTTPTransaction"
@interface NRMAHTTPTransactions : NRMAHarvestableArray <NRMAHarvestAware>
{
    NSMutableArray* httpTransactions;

}
- (void) add:(NRMAHarvestableHTTPTransaction*)transaction;
- (id) JSONObject;
- (void) clear;
@end
