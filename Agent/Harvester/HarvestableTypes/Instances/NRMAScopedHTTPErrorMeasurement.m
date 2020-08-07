//
//  NRMAScopedHTTPErrorMeasurement.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 11/6/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAScopedHTTPErrorMeasurement.h"
#import "NRMAHTTPErrorMeasurement.h"
@implementation NRMAScopedHTTPErrorMeasurement

- (id) initWithMeasurement:(NRMAHTTPErrorMeasurement *)measurement
{
    self = [super initWithMeasurement:measurement];
    if (self) {
        type = @"NETWORK";
        httpMethod = measurement.httpMethod;
        startTime = (long long)measurement.errorTime;
        endTime = (long long)measurement.errorTime;
        wanType = measurement.wanType;
        uri = measurement.url;
        statusCode = measurement.statusCode;
        NSURL* url = [NSURL URLWithString:uri];
        threadInfo  = measurement.threadInfo;
        rootURL = [NSString stringWithFormat:@"%@://%@",[url scheme],[url host]];
    }

    return self;
}

- (id) JSONObject
{
    NSMutableArray* jsonArray = [[NSMutableArray alloc] init];

    [jsonArray addObject:@{
            @"type"       : type,
            @"uri"        : uri,
            @"status_code": [NSNumber numberWithInteger:statusCode],
            @"http_method": httpMethod?:@"",
            @"wan_type"   :  wanType?:@""
    }];

    [jsonArray addObject:[NSNumber numberWithLongLong:startTime]];
    [jsonArray addObject:[NSNumber numberWithLongLong:endTime]];
    [jsonArray addObject:[NSString stringWithFormat:@"External/%@",rootURL]];
    [jsonArray addObject:@[[NSNumber numberWithInteger:threadInfo.identity],threadInfo.name?:@""]];
    [jsonArray addObject:[NSArray array]];
    return jsonArray;
}
@end
