//
//  NRMAHTTPError.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/19/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAHTTPError.h"

@implementation NRMAHTTPError
- (instancetype) initWithURL:(NSString*)url
                  httpMethod:(NSString*)httpMethod
                 timeOfError:(double)timeOfError_millis
                  statusCode:(int)statusCode
                responseBody:(NSString*)response
                  parameters:(NSDictionary*)parameters
                     wanType:(NSString*)wanType
                appDataToken:(NSString*)appData
                  threadInfo:(NRMAThreadInfo*)threadInfo
{
    self = [super init];
    if (self) {
        self.url = url;
        self.httpMethod = httpMethod;
        self.timeOfErrorMillis = timeOfError_millis;
        self.statusCode = statusCode;
        self.response = response;
        self.parameters = parameters;
        self.wanType = wanType;
        self.appData = appData;
        self.threadInfo = threadInfo;
    }
    return self;
}
@end
