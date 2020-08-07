//
//  NRMANSURLConnectionDelegateBase.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/21/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMANSURLConnectionDelegateBase.h"
#import "NRTimer.h"
#import "NRLogger.h"
#import "NRMANSURLConnectionSupport.h"
#import <objc/runtime.h>
#import "NewRelicAgentInternal.h"
#import "NRMANSURLConnectionSupport+private.h"
#import "NRMAHarvestController.h"

@implementation NRMANSURLConnectionDelegateBase {
    /*
     The client NSURLConnectionDelegate instance
     */
    __strong NSObject<NSURLConnectionDelegate, NSURLConnectionDataDelegate, NSURLConnectionDownloadDelegate, NSObject>* _realDelegate;

    /*
     The proxy NSURLConnection object we shimmed in
     */
    /*
     The HTTP Request instance
     */
    NSURLRequest* _request;
    /*
     The HTTP Response instance
     */
    NSURLResponse* _response;

    /*
     The response body data.
     */
    NSMutableData* _responseData;

    /*
     The timer for the total request time.
     */
    NRTimer* _timer;
    /*
     The total number of bytes received.
     */
    NSUInteger _bytesReceived;
    /*
     The total number of bytes actually sent.
     */
    NSUInteger _bytesSent;
}

@synthesize realDelegate = _realDelegate;
//@synthesize connectionWrapper = _connectionWrapper;
@synthesize response = _response;
@synthesize responseData = _responseData;
@synthesize request = _request;

- (void) dealloc {
    [self releaseChildren];
    [super dealloc];
}

- (void)releaseChildren {
    self.realDelegate = nil;
    [_response release];
    _response = nil;
    self.request = nil;
    [_responseData release];
    _responseData = nil;
    [_timer release];
    _timer = nil;
}

- (NRTimer*) timer
{
    return _timer;
}
/*
 Creates and starts a timer for this request if one hasn't already started
 */
- (void)startDownloadTimer
{
    if (nil == _timer) {
        _timer = [[NRTimer alloc] init];
    }
}






#pragma mark NSURLConnectionDelegate methods


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NRLOG_VERBOSE(@"connection:didFailWithError: for %@", connection.currentRequest.URL.absoluteString);

    [_timer stopTimer];

    [NRMANSURLConnectionSupport noticeError:error forRequest:_request withTimer:_timer];

    if ([_realDelegate respondsToSelector:@selector(connection:didFailWithError:)]) {
        [_realDelegate connection:connection didFailWithError:error];
    }
}



#pragma mark NSURLConnectionDataDelegate methods

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NRLOG_VERBOSE(@"connectionDidFinishLoading: for %@", connection.currentRequest.URL.absoluteString);
    [_timer stopTimer];

    [NRMANSURLConnectionSupport noticeResponse:_response
                                  forRequest:_request
                                   withTimer:_timer
                                     andBody:_responseData
                                   bytesSent:_bytesSent
                               bytesReceived:_bytesReceived];

    if ([_realDelegate respondsToSelector:@selector(connectionDidFinishLoading:)]) {
        [_realDelegate connectionDidFinishLoading:connection];
    }
}



- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NRLOG_VERBOSE(@"connection:didReceiveData: received %lu bytes for %@", (unsigned long)data.length, connection.currentRequest.URL.absoluteString);

    _bytesReceived += data.length;

    NSUInteger responseBodyLimit = [NRMAHarvestController configuration].response_body_limit;

    // capture the first responseBodyLimit bytes into _responseData
    // if this response ends up being an HTTP error we will send _responseData with our error trace
    if (! _responseData) {
        _responseData = [[NSMutableData alloc] initWithCapacity:responseBodyLimit];
    }
    if (data.length > 0 && _responseData.length < responseBodyLimit) {
        NSUInteger responseDataLeft = responseBodyLimit - _responseData.length;
        if (responseDataLeft > 0) {
            NSUInteger keepLength = data.length < responseDataLeft ? data.length : responseDataLeft;
            [_responseData appendData:[data subdataWithRange:NSMakeRange(0, keepLength)]];
        }
    }

    if ([_realDelegate respondsToSelector:@selector(connection:didReceiveData:)]) {
        [_realDelegate connection:connection didReceiveData:data];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NRLOG_VERBOSE(@"connection:didReceiveResponse: for %@", connection.currentRequest.URL.absoluteString);
    _response = [response retain];

    if ([_realDelegate respondsToSelector:@selector(connection:didReceiveResponse:)]) {
        [_realDelegate connection:connection didReceiveResponse:response];
    }
}

- (void)connection:(NSURLConnection *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    NRLOG_VERBOSE(@"connection:didSendBodyData: bytesWritten: %ld totalBytesWritten: %ld totalBytesExpectedToWrite:%ld for %@", (long)bytesWritten,
                  (long)totalBytesWritten,
                  (long)totalBytesExpectedToWrite,
                  connection.currentRequest.URL.absoluteString);

    if (totalBytesWritten >= 0) {
        _bytesSent = (NSUInteger)totalBytesWritten;
    }

    if ([_realDelegate respondsToSelector:@selector(connection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:)]) {
        [_realDelegate connection:connection
                  didSendBodyData:bytesWritten
                totalBytesWritten:totalBytesWritten
        totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    if (redirectResponse) {
        NSUInteger statusCode = 0;
        if ([redirectResponse respondsToSelector:@selector(statusCode)]) {
            statusCode = ((NSHTTPURLResponse *)redirectResponse).statusCode;
        }
        NRLOG_VERBOSE(@"REDIRECT %@ [%lu] ==> %@", redirectResponse.URL.absoluteString, (unsigned long)statusCode, request.URL.absoluteString);
    }
    else {
        NRLOG_VERBOSE(@"REQUEST %@", request.URL.absoluteString);
        if (!_timer) {
            [self startDownloadTimer];
        }
    }

    if ([_realDelegate respondsToSelector:@selector(connection:willSendRequest:redirectResponse:)]) {
        return [_realDelegate connection:connection willSendRequest:request redirectResponse:redirectResponse];
    }
    return request;
}



@end





