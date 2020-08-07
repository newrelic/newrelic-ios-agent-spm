//
//  NRMAHTTPTransactionMeasurement.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/5/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHTTPTransactionMeasurement.h"

@implementation NRMAHTTPTransactionMeasurement
- (id) initWithURL:(NSString*) URL
        statusCode:(int) statusCode
      responseBody:(NSString*) response
         bytesSent:(long long) bytesSent
     bytesReceived:(long long) bytesReceived
         totalTime:(double) totalTime
{
    self = [super initWithType:NRMAMT_HTTPTransaction];
    if (self){
        
    }
    return self;
}

- (id) initWithURL:(NSString*)URL
        httpMethod:(NSString*)httpMethod
           carrier:(NSString*)carrierName
         startTime:(double)beginTime
         totalTime:(double)totalTime
        statusCode:(int)statusCode
         errorCode:(int)errorCode
         bytesSent:(long long)bytesSent
     bytesReceived:(long long)bytesReceived
           appData:(NSString*)appData
           wanType:(NSString*)wanType
        threadInfo:(NRMAThreadInfo*)threadInfo
{
    self = [super initWithType:NRMAMT_HTTPTransaction];
    if (self) {
        self.url = URL;
        self.httpMethod = httpMethod;
        self.carrier = carrierName;
        self.totalTime = totalTime;
        self.endTime = totalTime + beginTime;
        self.startTime = beginTime; 
        self.statusCode = statusCode;
        self.errorCode = errorCode;
        self.bytesSent = bytesSent;
        self.bytesReceived = bytesReceived;
        self.crossProcessResponse = appData;
        self.wanType = wanType;
        self.threadInfo = threadInfo;
    }
    return self;
}


@end
