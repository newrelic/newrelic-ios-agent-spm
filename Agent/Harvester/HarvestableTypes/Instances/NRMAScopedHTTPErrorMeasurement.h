//
//  NRMAScopedHTTPErrorMeasurement.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 11/6/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAScopedMeasurement.h"

@interface NRMAScopedHTTPErrorMeasurement : NRMAScopedMeasurement
{
    NSString* type;
    NSString* httpMethod;
    long long startTime;
    long long endTime;
    NSString* uri;
    int statusCode;
    NSString* rootURL;
    NSString* wanType;
    NRMAThreadInfo* threadInfo;

}
@end
