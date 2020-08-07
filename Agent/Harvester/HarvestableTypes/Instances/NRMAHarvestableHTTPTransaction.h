//
//  NRMAHarvestableHTTPTransaction.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/24/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestableArray.h"

@interface NRMAHarvestableHTTPTransaction : NRMAHarvestableArray
@property(nonatomic,strong) NSString*   url;
@property(nonatomic, strong) NSString*  httpMethod;
@property(nonatomic,strong) NSString*   carrier;
@property(nonatomic)        int         statusCode;
@property(nonatomic)        long long   bytesSent;
@property(nonatomic)        int         errorCode;
@property(nonatomic)        long long   bytesReceived;
@property(nonatomic)        double      startTimeSeconds;
@property(nonatomic)        double      totalTimeSeconds;
@property(nonatomic,strong) NSString* wanType;
@property(nonatomic,strong) NSString*   crossProcessResponse;

- (id) initWithURL:(NSString*)URL
        httpMethod:(NSString*)httpMethod
           carrier:(NSString*)carrier
      responseTime:(long long)responseTime
        statusCode:(int)statusCode
         errorCode:(int)errorCode
         bytesSent:(long long)bytesSent
     bytesReceived:(long long)bytesReceived
           wanType:(NSString*)wanType
crossProcessResponse:(NSString*)crossProcessResponse;
@end
