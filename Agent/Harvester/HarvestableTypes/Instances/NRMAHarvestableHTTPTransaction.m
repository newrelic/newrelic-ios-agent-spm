//
//  NRMAHarvestableHTTPTransaction.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/24/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestableHTTPTransaction.h"

@implementation NRMAHarvestableHTTPTransaction
- (id) initWithURL:(NSString*)URL
        httpMethod:(NSString*)httpMethod
           carrier:(NSString*)carrier
      responseTime:(long long)responseTime
        statusCode:(int)statusCode
         errorCode:(int)errorCode
         bytesSent:(long long)bytesSent
     bytesReceived:(long long)bytesReceived
           wanType:(NSString*)wanType
crossProcessResponse:(NSString*)crossProcessResponse
{
    self = [super init];
    if (self) {
        self.url = URL;
        self.httpMethod = httpMethod;
        self.carrier= carrier;
        self.totalTimeSeconds =responseTime/1000;
        self.statusCode= self.statusCode;
        self.errorCode = errorCode;
        self.bytesSent = bytesSent;
        self.bytesReceived = bytesReceived;
        self.bytesSent = bytesSent;
        self.wanType = wanType;
        self.crossProcessResponse = crossProcessResponse;
    }
    
    return self;
}


- (id) JSONObject
{
    NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity:9];
    [array addObject:self.url];
    [array addObject:self.carrier];
    [array addObject:[NSNumber numberWithDouble:self.totalTimeSeconds]];
    [array addObject:[NSNumber numberWithInt:self.statusCode]];
    [array addObject:[NSNumber numberWithInt:self.errorCode]];
    [array addObject:[NSNumber numberWithLongLong:self.bytesSent]];
    [array addObject:[NSNumber numberWithLongLong:self.bytesReceived]];
    [array addObject:self.crossProcessResponse?:[NSNull null]];
    [array addObject:self.wanType?:@""];
    [array addObject:self.httpMethod?:@""];
    return array;
}

@end
