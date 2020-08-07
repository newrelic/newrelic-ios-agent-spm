//
//  NRMAHTTPTransaction.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/19/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAHTTPTransaction.h"

@implementation NRMAHTTPTransaction
- (instancetype) initWithURL:(NSString*)url
                  httpMethod:(NSString*)httpMethod
                   startTime:(double)startTime
                   totalTime:(double)totalTime
                   bytesSent:(long long)bytesSent
               bytesReceived:(long long)bytesReceived
                  statusCode:(int)statusCode
                 failureCode:(int)failureCode
                     appData:(NSString*)appdata
                     wanType:(NSString*)wanType
                  threadInfo:(NRMAThreadInfo*)threadInfo
{
    self = [super init];
    if (self) {
        self.url = url;
        self.httpMethod = httpMethod;
        self.startTimeMillis   = startTime;
        self.totalTimeMillis = totalTime;
        self.dataSentBytes = bytesSent;
        self.dataReceivedBytes = bytesReceived;
        self.statusCode = statusCode;
        self.failureCode = failureCode;
        self.crossProccessResponse = appdata;
        self.wanType = wanType;
        self.threadInfo = threadInfo;
    }
    return self;
}
@end
