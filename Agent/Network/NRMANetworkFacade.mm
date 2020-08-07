//
// Created by Bryce Buchanan on 2/7/18.
// Copyright (c) 2018 New Relic. All rights reserved.
//

#import "NRMANetworkFacade.h"
#import "NRTimer.h"
#import "NRLogger.h"
#import "NRMANetworkResponseData.h"
#import "NRMANetworkRequestData.h"
#import "NewRelicInternalUtils.h"
#import "NRMAThreadInfo.h"
#import "NRMATaskQueue.h"
#import "NRMAHTTPTransaction.h"
#import "NRMAFlags.h"
#import "NRMAHTTPError.h"
#import "NRMAHarvestController.h"
#import <Connectivity/Payload.hpp>
#import "NRMAPayloadContainer+cppInterface.h"
#import "NRMAAnalytics+cppInterface.h"
#import "NewRelicAgentInternal.h"
#import "NRMAHTTPUtilities+cppInterface.h"

@implementation NRMANetworkFacade {

}

+ (int) insightsAttributeSizeLimit {
    return NRMA_INSIGHTS_ATTRIBUTE_SIZE_LIMIT;
}

+ (NSString*) generateResponseBody:(NSData*)responseBody
                         sizeLimit:(int)sizeLimit {
    if (responseBody.length > sizeLimit) {
        responseBody = [responseBody subdataWithRange:NSMakeRange(0,
                                                                  sizeLimit)];
    }
    return [[NSString alloc] initWithData:responseBody
                                 encoding:NSUTF8StringEncoding];
}

+ (NSString*) getAppDataHeader:(NSURLResponse*)response {
    return [response isKindOfClass:[NSHTTPURLResponse class]]?[((NSHTTPURLResponse*)response) allHeaderFields][NEW_RELIC_SERVER_METRICS_HEADER_KEY]:@"";
}


+ (NSDictionary*) headers:(NSURLResponse*)response {
    return [response isKindOfClass:[NSHTTPURLResponse class]]?[((NSHTTPURLResponse*)response) allHeaderFields]:@{};
}

+ (NSInteger) statusCode:(NSURLResponse*)response {
    return [response isKindOfClass:[NSHTTPURLResponse class]]?[((NSHTTPURLResponse*)response) statusCode]:0;
}

+ (NSString*) contentType:(NSURLResponse*)response {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSString* contentType = [((NSHTTPURLResponse*)response) allHeaderFields][@"Content-Type"];
        if (contentType.length && contentType.length < DEFAULT_RESPONSE_CONTENT_TYPE_LIMIT) {
            return contentType;
        }
    }
    return nil;
}

+ (NSString*) contentLength:(NSURLResponse*)response {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        return [((NSHTTPURLResponse*)response) allHeaderFields][@"Content-Length"];
    }
    return nil;
}

+ (NSString*) responseBodyForMetrics:(NSData*)responseData {
    if ([NRMAFlags shouldEnableHttpResponseBodyCapture] && responseData) {
        return [NRMANetworkFacade generateResponseBody:responseData
                                             sizeLimit:[NRMANetworkFacade responseBodyCaptureSizeLimit]];
    }
    return @"";
}

+ (NSString*) responseBodyForEvents:(NSData*)responseData {
    if ([NRMAFlags shouldEnableHttpResponseBodyCapture] && responseData) {
        return [NRMANetworkFacade generateResponseBody:responseData
                                             sizeLimit:[NRMANetworkFacade insightsAttributeSizeLimit]];
    } else if (![NRMAFlags shouldEnableHttpResponseBodyCapture]) {
        return @"NEWRELIC_RESPONSE_BODY_CAPTURE_DISABLED";
    }
    return @"";

}


+ (void) noticeNetworkRequest:(NSURLRequest*)request
                     response:(NSURLResponse*)response
                    withTimer:(NRTimer*)timer
                    bytesSent:(NSUInteger)bytesSent
                bytesReceived:(NSUInteger)bytesReceived
                 responseData:(NSData*)responseData
                       params:(NSDictionary*)params {

    [timer stopTimer];
    double startTime = timer.startTimeInMillis;
    double duration = timer.timeElapsedInMilliSeconds;

    if (![NRMANetworkFacade canInstrumentRequestWithUrl:request.URL
                                          withStartTime:startTime
                                           withDuration:duration]) {
        return;
    }


    __block NRMAThreadInfo* threadInfo = [NRMAThreadInfo new];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {

        //getCurrentWanType shouldn't be called on the main thread
        NSString* connectionType = [NewRelicInternalUtils getCurrentWanType];

        NRMANetworkRequestData* networkRequestData = [[NRMANetworkRequestData alloc] initWithRequestUrl:request.URL
                                                                                             httpMethod:[request HTTPMethod]
                                                                                         connectionType:connectionType
                                                                                            contentType:[NRMANetworkFacade contentType:response]
                                                                                              bytesSent:bytesSent];

        if ([NRMANetworkFacade statusCode:response] >= NRMA_HTTP_STATUS_CODE_ERROR_THRESHOLD) {

            /*
             * Params
             */

            // our bytesReceived value is not quite correct - it reflects the uncompressed byte length
            NSMutableDictionary* customParams = [@{
                    NRMA_ERROR_CONTENT_TYPE_KEY:[NRMANetworkFacade contentType:response]?:@"",
                    NRMA_ERROR_CONTENT_LENGTH_KEY:[NRMANetworkFacade contentLength:response] == nil?@(bytesReceived):@([[NRMANetworkFacade contentLength:response] integerValue]),
                    @"http_method":[request HTTPMethod]?:@"",
                    @"wan_type":connectionType?:@""
            } mutableCopy];

            /*
             * \Params
             */

            [[[NewRelicAgentInternal sharedInstance] analyticsController] addHTTPErrorEvent:networkRequestData
                                                                               withResponse:[[NRMANetworkResponseData alloc] initWithHttpError:[NRMANetworkFacade statusCode:response]
                                                                                                                                 bytesReceived:bytesReceived
                                                                                                                                  responseTime:[timer timeElapsedInSeconds]
                                                                                                                           networkErrorMessage:nil
                                                                                                                           encodedResponseBody:[NRMANetworkFacade responseBodyForEvents:responseData]
                                                                                                                                 appDataHeader:[NRMANetworkFacade getAppDataHeader:response]]
                                                                                withPayload:[NRMAHTTPUtilities retreivePayload:request]];

            NSMutableDictionary* mutableParams = [[NSMutableDictionary alloc] initWithDictionary:params?:@{}];
            mutableParams[NRMA_ERROR_CUSTOM_PARAMS_KEY] = customParams;


            [NRMATaskQueue queue:[[NRMAHTTPError alloc] initWithURL:request.URL.absoluteString
                                                         httpMethod:[request HTTPMethod]
                                                        timeOfError:timer.endTimeMillis
                                                         statusCode:(int)[NRMANetworkFacade statusCode:response]
                                                       responseBody:[NRMANetworkFacade responseBodyForMetrics:responseData]
                                                         parameters:mutableParams
                                                            wanType:connectionType
                                                       appDataToken:[NRMANetworkFacade getAppDataHeader:response]
                                                         threadInfo:threadInfo]];

        } else {

            [[[NewRelicAgentInternal sharedInstance] analyticsController] addNetworkRequestEvent:networkRequestData
                                                                                    withResponse:[[NRMANetworkResponseData alloc] initWithSuccessfulResponse:[NRMANetworkFacade statusCode:response]
                                                                                                                                               bytesReceived:bytesReceived
                                                                                                                                                responseTime:[timer timeElapsedInSeconds]]
                                                                                     withPayload:[NRMAHTTPUtilities retreivePayload:request]];

        }

        [NRMATaskQueue queue:[[NRMAHTTPTransaction alloc] initWithURL:request.URL.absoluteString
                                                           httpMethod:[request HTTPMethod]
                                                            startTime:startTime
                                                            totalTime:duration
                                                            bytesSent:bytesSent
                                                        bytesReceived:bytesReceived
                                                           statusCode:(int)[NRMANetworkFacade statusCode:response]
                                                          failureCode:0
                                                              appData:[NRMANetworkFacade getAppDataHeader:response]
                                                              wanType:connectionType
                                                           threadInfo:threadInfo]];

        //force a dequeue immediately (no waiting 1 second for auto dequeue.)
        [NRMATaskQueue synchronousDequeue];
    });
}

+ (void) noticeNetworkFailure:(NSURLRequest*)request
                    withTimer:(NRTimer*)timer
                    withError:(NSError*)error {

    [timer stopTimer];
    double startTime = timer.startTimeInMillis;
    double duration = timer.timeElapsedInMilliSeconds;

    if (![NRMANetworkFacade canInstrumentFailedRequestWithUrl:request.URL
                                                withStartTime:startTime
                                                 withDuration:duration]) {
        return;
    }

    __block NRMAThreadInfo* threadInfo = [NRMAThreadInfo new];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
        NSString* connectionType = [NewRelicInternalUtils getCurrentWanType];

        [[[NewRelicAgentInternal sharedInstance] analyticsController] addNetworkErrorEvent:[[NRMANetworkRequestData alloc] initWithRequestUrl:request.URL
                                                                                                                                   httpMethod:[request HTTPMethod]
                                                                                                                               connectionType:connectionType
                                                                                                                                  contentType:[request allHTTPHeaderFields][@"Content-Type"]
                                                                                                                                    bytesSent:0]
                                                                              withResponse:[[NRMANetworkResponseData alloc] initWithNetworkError:error.code
                                                                                                                                   bytesReceived:0
                                                                                                                                    responseTime:timer.timeElapsedInSeconds
                                                                                                                             networkErrorMessage:error.localizedDescription]
                                                                               withPayload:[NRMAHTTPUtilities retreivePayload:request]];


        [NRMATaskQueue queue:[[NRMAHTTPTransaction alloc] initWithURL:request.URL.absoluteString
                                                           httpMethod:[request HTTPMethod]
                                                            startTime:startTime
                                                            totalTime:duration
                                                            bytesSent:0
                                                        bytesReceived:0
                                                           statusCode:0
                                                          failureCode:(int)error.code
                                                              appData:nil
                //getCurrentWanType shouldn't be called on the main thread
                //because it calls a blocking method to get connection flags
                                                              wanType:connectionType
                                                           threadInfo:threadInfo]];
        //force a dequeue immediately (no waiting 1 second for auto dequeue.)
        [NRMATaskQueue synchronousDequeue];
    });
}

+ (bool) canInstrumentRequestWithUrl:(NSURL*)url
                       withStartTime:(double)startTime
                        withDuration:(double)duration {
    return [NRMANetworkFacade canInstrumentRequest:@"network request"
                                           withUrl:url
                                     withStartTime:startTime
                                      withDuration:duration];
}

+ (bool) canInstrumentFailedRequestWithUrl:(NSURL*)url
                             withStartTime:(double)startTime
                              withDuration:(double)duration {
    return [NRMANetworkFacade canInstrumentRequest:@"failed request"
                                           withUrl:url
                                     withStartTime:startTime
                                      withDuration:duration];
}

+ (bool) canInstrumentRequest:(NSString*)loggingKey
                      withUrl:(NSURL*)url
                withStartTime:(double)startTime
                 withDuration:(double)duration {
    bool canInstrument = true;

    if (!url) {
        NRLOG_WARNING(@"Ignoring %@ with a nil URL.", loggingKey);
        canInstrument = false;
    }
    if (url.absoluteString.length < 10) {
        NRLOG_WARNING(@"Ignoring %@ with an invalid URL: %@", loggingKey, url.absoluteString);
        canInstrument = false;
    }
    if (startTime <= 0) {
        NRLOG_WARNING(@"Ignoring %@ with invalid start time (%lf): %@",
                      loggingKey,
                      startTime,
                      url.absoluteString);
        canInstrument = false;
    }
    if (duration < 0) {
        NRLOG_WARNING(@"Ignoring %@ with negative duration (%lf): %@",
                      loggingKey,
                      duration,
                      url.absoluteString);
        canInstrument = false;
    }

    return canInstrument;
}

+ (int) responseBodyCaptureSizeLimit {
    return [NRMAHarvestController configuration].response_body_limit;
}


- (NSString*) crossProcessId {
    return [[[NRMAHarvestController harvestController] harvester] crossProcessID];
}

@end
