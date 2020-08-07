//
//  Copyright © 2018 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NRMANetworkResponseData : NSObject

-(id) initWithSuccessfulResponse:(NSInteger)statusCode
                   bytesReceived:(NSInteger)bytesReceived
                    responseTime:(double)timeInSeconds;

-(id) initWithNetworkError:(NSInteger)networkErrorCode
             bytesReceived:(NSInteger)bytesReceived
              responseTime:(double)timeInSeconds
       networkErrorMessage:(NSString*)errorMessage;

-(id) initWithHttpError:(NSUInteger)statusCode
          bytesReceived:(NSInteger)bytesReceived
           responseTime:(double)timeInSeconds
    networkErrorMessage:(NSString*)errorMessage
    encodedResponseBody:(NSString*)encodedResponseBody
          appDataHeader:(NSString*)appDataHeader;

-(void) dealloc;

@end
