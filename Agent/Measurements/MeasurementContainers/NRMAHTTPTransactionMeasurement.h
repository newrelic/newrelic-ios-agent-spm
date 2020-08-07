//
//  NRMAHTTPTransactionMeasurement.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/5/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMeasurement.h"

@interface NRMAHTTPTransactionMeasurement : NRMAMeasurement
@property(nonatomic,strong) NSString*   url;
@property(nonatomic,strong) NSString*   httpMethod;
@property(nonatomic,strong) NSString*   carrier;
@property(nonatomic)        int         statusCode;
@property(nonatomic)        long long   bytesSent;
@property(nonatomic)        int         errorCode;
@property(nonatomic)        long long   bytesReceived; 
@property(nonatomic)        double      totalTime;
@property(nonatomic,strong) NSString*   crossProcessResponse;
@property(nonatomic,strong) NSString* wanType;

- (id) initWithURL:(NSString*)URL
        httpMethod:(NSString*)httpMethod
           carrier:(NSString*)carrierName
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
