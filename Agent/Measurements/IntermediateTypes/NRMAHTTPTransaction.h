//
//  NRMAHTTPTransaction.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/19/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAThreadInfo.h"

@interface NRMAHTTPTransaction : NSObject
@property(strong) NSString* url;
@property(strong) NSString* httpMethod;
@property(assign) double startTimeMillis;
@property(assign) double totalTimeMillis;
@property(assign) long long dataSentBytes;
@property(assign) long long dataReceivedBytes;
@property(assign) int statusCode;
@property(assign) int failureCode;
@property(strong) NSString* wanType;
@property(strong) NRMAThreadInfo* threadInfo;
@property(strong) NSString* crossProccessResponse;


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
                  threadInfo:(NRMAThreadInfo*)threadInfo;
@end
