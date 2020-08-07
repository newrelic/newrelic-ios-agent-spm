//
//  NRMAHTTPTransactionMeasurementProducer.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/5/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMeasurementProducer.h"

@interface NRMAHTTPTransactionMeasurementProducer : NRMAMeasurementProducer

- (id)init;

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
                     threadInfo:(NRMAThreadInfo*)threadInfo;
@end
