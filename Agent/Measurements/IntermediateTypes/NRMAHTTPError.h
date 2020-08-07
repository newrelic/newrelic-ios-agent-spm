//
//  NRMAHTTPError.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/19/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAThreadInfo.h"
@interface NRMAHTTPError : NSObject
@property(strong) NSString* url;
@property(strong) NSString* httpMethod;
@property(assign) double timeOfErrorMillis;
@property(assign) int statusCode;
@property(strong) NSString* response;
@property(strong) NSDictionary* parameters;
@property(strong) NSString* wanType;
@property(strong) NSString* appData;
@property(strong) NRMAThreadInfo* threadInfo;


- (instancetype) initWithURL:(NSString*)url
                  httpMethod:(NSString*)httpMethod
                 timeOfError:(double)timeOfError_millis
                  statusCode:(int)statusCode
                responseBody:(NSString*)response
                  parameters:(NSDictionary*)parameters
                     wanType:(NSString*)wanType
                appDataToken:(NSString*)appData
                  threadInfo:(NRMAThreadInfo*)threadInfo;
@end
