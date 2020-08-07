//
//  NRMAHTTPErrorMeasurement.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/26/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMeasurement.h"

@interface NRMAHTTPErrorMeasurement : NRMAMeasurement
@property(strong,nonatomic) NSString* url;
@property(strong, nonatomic) NSString* httpMethod;
@property(nonatomic) int statusCode;
@property(strong, nonatomic) NSString* responseBody;
@property(strong, nonatomic) NSString* stackTrace;
@property(strong, nonatomic) NSString* wanType;
@property(strong, nonatomic) NSDictionary* parameters;
@property(strong, nonatomic) NSString* appData;
@property(nonatomic)  double errorTime;
- (id) initWithURL:(NSString*)URL statusCode:(int)statusCode;
@end
