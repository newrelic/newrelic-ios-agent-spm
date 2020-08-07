//
// Created by Bryce Buchanan on 5/2/17.
// Copyright (c) 2017 New Relic. All rights reserved.
//

#import "NRMAConnection.h"
#import "NRMAHarvestController.h"
#import "NewRelicInternalUtils.h"
#import "NewRelicAgentInternal.h"
#import "NRMAConnectInformation.h"

#define kTIMEOUT_INTERVAL         20

@implementation NRMAConnection

- (NSURLRequest*) newPostWithURI:(NSString*)uri {
    NSMutableURLRequest* postRequest = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:uri]];

    postRequest.HTTPMethod = @"POST";
    postRequest.timeoutInterval = kTIMEOUT_INTERVAL;
    [postRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    if (![self.applicationToken length]) {
        NRLOG_ERROR(@"cannot create post request without Application Token.");
        return nil;
    }

    [postRequest addValue:self.applicationToken forHTTPHeaderField:(NSString*)kAPPLICATION_TOKEN_HEADER];

    [postRequest setValue:self.applicationVersion forHTTPHeaderField:NEW_RELIC_APP_VERSION_HEADER_KEY];
    [postRequest setValue:[NewRelicInternalUtils osName] forHTTPHeaderField:NEW_RELIC_OS_NAME_HEADER_KEY];

    return postRequest;
}





@end
