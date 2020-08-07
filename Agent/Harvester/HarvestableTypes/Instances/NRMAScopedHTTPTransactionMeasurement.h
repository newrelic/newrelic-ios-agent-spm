//
//  NRMAScopedHTTPTransactionMeasurement.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/4/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAScopedMeasurement.h"
#import "NRMAThreadInfo.h"
@interface NRMAScopedHTTPTransactionMeasurement : NRMAScopedMeasurement
{
    NSUInteger statusCode;
    NSInteger errorCode;
    NSString* carrier;
    long long bytesReceived;

    long long bytesSent;
    NSString* type;
    NSString* uri;
    NSString* httpMethod;
    long long startTime;
    long long endTime;
    NSString* wanType;
    NSString* cross_process_data;
    NSString* rootURL;
    
    NSDictionary* custom_params;
    NRMAThreadInfo* threadInfo;
}

@end
