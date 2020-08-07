//
// Created by Bryce Buchanan on 2/7/18.
// Copyright (c) 2018 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAPayloadContainer.h"

@class NRTimer;

#define NEW_RELIC_CROSS_PROCESS_ID_HEADER_KEY   @"X-NewRelic-ID"
#define NEW_RELIC_SERVER_METRICS_HEADER_KEY     @"X-NewRelic-App-Data"
#define NRMA_INSIGHTS_ATTRIBUTE_SIZE_LIMIT 4096    // bytes
#define NRMA_ERROR_CUSTOM_PARAMS_KEY      @"custom_params"
#define NRMA_ERROR_CONTENT_TYPE_KEY       @"content_type"
#define NRMA_ERROR_CONTENT_LENGTH_KEY     @"content_length"
#define DEFAULT_RESPONSE_CONTENT_TYPE_LIMIT 256

@interface NRMANetworkFacade : NSObject

+ (void) noticeNetworkRequest:(NSURLRequest*)request
                     response:(NSURLResponse*)response
                    withTimer:(NRTimer*)timer
                    bytesSent:(NSUInteger)bytesSent
                bytesReceived:(NSUInteger)bytesReceived
                 responseData:(NSData*)responseData
                       params:(NSDictionary*)params;

+ (void) noticeNetworkFailure:(NSURLRequest*)request
                    withTimer:(NRTimer*)timer
                    withError:(NSError*)error;
@end
