//
//  NRMAHarvestableHTTPTransactionGeneration.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/24/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestableHTTPTransactionGeneration.h"
#import "NRMAHarvestable.h"
#import "NRMAHarvestableHTTPTransaction.h"
#import "NRMAHTTPTransactions.h"
#import "NRMAHTTPTransactionMeasurement.h"
#import "NRMAHarvestController.h"
@implementation NRMAHarvestableHTTPTransactionGeneration
- (id) init
{
    self = [super initWithType:NRMAMT_HTTPTransaction];
    if (self) {
        
    }
    return self;
}

- (void) consumeMeasurement:(NRMAMeasurement*)measurement
{
    NRMAHTTPTransactionMeasurement* httpTransactionMeasurement = nil;
    if (measurement.type != NRMAMT_HTTPTransaction) {
        return;
    }
    
    httpTransactionMeasurement = (NRMAHTTPTransactionMeasurement*)measurement;
    
    
    NRMAHarvestableHTTPTransaction* httpTransaction = [[NRMAHarvestableHTTPTransaction alloc] init];
    httpTransaction.url = httpTransactionMeasurement.url;
    httpTransaction.httpMethod = httpTransactionMeasurement.httpMethod;
    httpTransaction.carrier = httpTransactionMeasurement.carrier;
    httpTransaction.statusCode = httpTransactionMeasurement.statusCode;
    httpTransaction.errorCode = httpTransactionMeasurement.errorCode;
    httpTransaction.bytesReceived = httpTransactionMeasurement.bytesReceived;
    httpTransaction.bytesSent = httpTransactionMeasurement.bytesSent;
    httpTransaction.totalTimeSeconds = httpTransactionMeasurement.totalTime /1000;
    httpTransaction.startTimeSeconds = httpTransactionMeasurement.startTime/1000;
    httpTransaction.wanType = httpTransactionMeasurement.wanType;
    httpTransaction.crossProcessResponse = httpTransactionMeasurement.crossProcessResponse;
    
    [NRMAHarvestController addHarvestableHTTPTransaction:httpTransaction];
}
@end
