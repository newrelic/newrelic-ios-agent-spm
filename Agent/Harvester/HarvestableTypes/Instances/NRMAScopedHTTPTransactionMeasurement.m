//
//  NRMAScopedHTTPTransactionMeasurement.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/4/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAScopedHTTPTransactionMeasurement.h"
#import "NRMAHTTPTransactionMeasurement.h"
@implementation NRMAScopedHTTPTransactionMeasurement

- (id) initWithMeasurement:(NRMAHTTPTransactionMeasurement *)measurement
{
    self = [super initWithMeasurement:measurement];
    if (self) {
        statusCode = measurement.statusCode;
        errorCode = measurement.errorCode;
        carrier = measurement.carrier;
        bytesSent = measurement.bytesSent;
        bytesReceived = measurement.bytesReceived;
        cross_process_data = measurement.crossProcessResponse;
        type = @"NETWORK";
        startTime = (long long)measurement.startTime;
        endTime = (long long)measurement.endTime;
        uri = measurement.url;
        httpMethod = measurement.httpMethod;
        wanType = measurement.wanType;
        NSURL* url = [NSURL URLWithString:uri];
        rootURL = [NSString stringWithFormat:@"%@://%@",[url scheme],[url host]];
       
    }
    return self;
}


- (id) JSONObject
{
    NSMutableArray* jsonArray = [[NSMutableArray alloc] init];

    [jsonArray addObject:@{
            @"type":type,
            @"uri":uri,
            @"carrier":carrier?:@"",
            @"status_code": [NSNumber numberWithInteger:statusCode],
            @"error_code": [NSNumber numberWithInteger:errorCode],
            @"bytes_sent" : [NSNumber numberWithLongLong:bytesSent],
            @"bytes_received":[NSNumber numberWithLongLong:bytesReceived],
            @"cross_process_data":cross_process_data?:@"",
            @"custom_params":custom_params?:[NSDictionary dictionary],
            @"wan_type": wanType?:@"",
            @"http_method":httpMethod?:@""
    }];
    
    [jsonArray addObject:[NSNumber numberWithLongLong:startTime]];
    [jsonArray addObject:[NSNumber numberWithLongLong:endTime]];
    [jsonArray addObject:[NSString stringWithFormat:@"External/%@",rootURL]];
    [jsonArray addObject:@[[NSNumber numberWithInteger:threadInfo.identity],threadInfo.name?:@""]];
    [jsonArray addObject:[NSArray array]];
    return jsonArray;
}
@end

