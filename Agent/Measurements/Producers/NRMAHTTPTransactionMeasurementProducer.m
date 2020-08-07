//
//  NRMAHTTPTransactionMeasurementProducer.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/5/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHTTPTransactionMeasurementProducer.h"
#import "NRMAHTTPTransactionMeasurement.h"
#import "NewRelicInternalUtils.h"

@implementation NRMAHTTPTransactionMeasurementProducer
- (id)init {
    return [super initWithType:NRMAMT_HTTPTransaction];
}

- (id)initWithType:(NRMAMeasurementType)type {
    @throw [NRMAMeasurementException exceptionWithName:NRMAMeasurementTypeConsistencyError
                                                reason:@"Use -init to initialize NRMAHTTPTransactionMeasurementProducer"
                                              userInfo:nil];
}


- (void) produceHttpTransaction:(NSString*)url
                     httpMethod:(NSString*)httpMethod
                        carrier:(NSString*)carrier
                      startTime:(double)startTime
                      totalTime:(double)totalTime
                     statusCode:(int)statusCode
                      errorCode:(int)errorCode
                      bytesSent:(long long)bytesSent
                  bytesReceived:(long long)bytesReceived
                        appData:(NSString*)appData
                        wanType:(NSString*)wanType
                     threadInfo:(NRMAThreadInfo*)threadInfo
{
    NRMAHTTPTransactionMeasurement *measurement = [[NRMAHTTPTransactionMeasurement alloc] initWithURL:[NewRelicInternalUtils normalizedStringFromString:url]
                                                                                           httpMethod:httpMethod
                                                                                              carrier:carrier
                                                                                            startTime:startTime
                                                                                            totalTime:totalTime
                                                                                           statusCode:statusCode
                                                                                            errorCode:errorCode
                                                                                            bytesSent:bytesSent
                                                                                        bytesReceived:bytesReceived
                                                                                              appData:appData
                                                                                              wanType:wanType
                                                                                           threadInfo:threadInfo];

    [self produceMeasurement:measurement];

}


@end
