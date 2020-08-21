//
//  Copyright © 2018 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMANetworkResponseData.h"
#import "Analytics/NetworkResponseData.hpp"
#import "NewRelicInternalUtils.h"
#import "NRMABase64.h"

@interface NRMANetworkResponseData () {
    NewRelic::NetworkResponseData* wrappedNetworkResponseData;
}
@end

@implementation NRMANetworkResponseData

-(id) initWithSuccessfulResponse:(NSInteger)statusCode
                   bytesReceived:(NSInteger)bytesReceived
                    responseTime:(double)timeInSeconds {
    self = [super init];
    if(self) {
        wrappedNetworkResponseData = new NewRelic::NetworkResponseData(statusCode, bytesReceived, timeInSeconds);
        if(!wrappedNetworkResponseData)
            self = nil;
    }
    return self;
}
 
 -(id) initWithNetworkError:(NSInteger)networkErrorCode
              bytesReceived:(NSInteger)bytesReceived
               responseTime:(double)timeInSeconds
        networkErrorMessage:(NSString*)errorMessage {
     self = [super init];
     if(self) {
         wrappedNetworkResponseData = new NewRelic::NetworkResponseData(networkErrorCode,
                                                                        bytesReceived,
                                                                        timeInSeconds,
                                                                        errorMessage.UTF8String);
         if(!wrappedNetworkResponseData)
             self = nil;
     }
     return self;
 }

-(id) initWithHttpError:(NSUInteger)statusCode
          bytesReceived:(NSInteger)bytesReceived
           responseTime:(double)timeInSeconds
    networkErrorMessage:(NSString*)errorMessage
    encodedResponseBody:(NSString*)responseBody
          appDataHeader:(NSString*)appDataHeader {
    self = [super init];
    if(self) {
        
        NSString* encodedResponseBody = @"";
        if (responseBody.length) {
            encodedResponseBody = [NRMABase64 encodeFromData:[responseBody dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        wrappedNetworkResponseData = new NewRelic::NetworkResponseData(statusCode,
                                                                       bytesReceived,
                                                                       timeInSeconds,
                                                                       errorMessage.UTF8String,
                                                                       encodedResponseBody.UTF8String,
                                                                       appDataHeader.UTF8String);
        if(!wrappedNetworkResponseData)
            self = nil;
    }
    return self;
}

-(NewRelic::NetworkResponseData*) getNetworkResponseData {
    return wrappedNetworkResponseData;
}

-(void) dealloc {
    delete wrappedNetworkResponseData;
    [super dealloc];
}

@end

