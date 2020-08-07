//
//  NRMAHarvesterConnection.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/27/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NewRelicInternalUtils.h"
#import "NRMAExceptionHandler.h"
#import "NRMAMeasurements.h"
#import <zlib.h>
#import "NRMATaskQueue.h"
#import <time.h>
@implementation NRMAHarvesterConnection
@synthesize connectionInformation = _connectionInformation;
- (id) init
{
    self = [super init];
    if (self) {
        self.harvestSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    }
    return self;
}
- (NSURLRequest*) createPostWithURI:(NSString*)url message:(NSString*)message
{
    NSMutableURLRequest * postRequest = [super newPostWithURI:url];

    NSString* contentEncoding = message.length <= 512 ? @"identity" : @"deflate";

    [postRequest addValue:contentEncoding forHTTPHeaderField:@"Content-Encoding"];

    if (self.serverTimestamp != 0) {
        [postRequest addValue:[NSString stringWithFormat:@"%lld",self.serverTimestamp]
           forHTTPHeaderField:(NSString*)kCONNECT_TIME_HEADER];
    }

    NSData* messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
    if ([contentEncoding isEqualToString:@"deflate"]) {
        z_stream zStream;
        
        zStream.zalloc = Z_NULL;
        zStream.zfree = Z_NULL;
        zStream.opaque = Z_NULL;
        zStream.next_in = (Bytef *)messageData.bytes;
        zStream.avail_in = (uint)messageData.length;
        zStream.total_out = 0;
        
        if (deflateInit(&zStream, Z_DEFAULT_COMPRESSION) == Z_OK) {
            NSUInteger compressionChunkSize = 16384; // 16Kb
            NSMutableData *compressedData = [NSMutableData dataWithLength:compressionChunkSize];
            
            do {
                if (zStream.total_out >= [compressedData length]) {
                    [compressedData increaseLengthBy:compressionChunkSize];
                }
                
                zStream.next_out = [compressedData mutableBytes] + zStream.total_out;
                zStream.avail_out = (unsigned int)[compressedData length] - (unsigned int)zStream.total_out;

                deflate(&zStream, Z_FINISH);
                
            } while (zStream.avail_out == 0);
            
            deflateEnd(&zStream);
            [compressedData setLength:zStream.total_out];
            
            messageData = [NSData dataWithData:compressedData];
        }
    }
    [postRequest setHTTPBody:messageData];
    
    return postRequest;
}

- (NRMAHarvestResponse*) send:(NSURLRequest *)post
{
    NRMAHarvestResponse* harvestResponse = [[NRMAHarvestResponse alloc] init];
    __block NSHTTPURLResponse* response;
    __block NSError* error;
    __block NSData* data;

    __block dispatch_semaphore_t harvestRequestSemaphore = dispatch_semaphore_create(0);

    [[self.harvestSession uploadTaskWithRequest:post
                                       fromData:post.HTTPBody
                              completionHandler:^(NSData* responseBody, NSURLResponse* bresponse, NSError* berror){
        @autoreleasepool {
            data = responseBody;
            error = berror;
            response = (NSHTTPURLResponse*)bresponse;
            dispatch_semaphore_signal(harvestRequestSemaphore);
        }
    }] resume];

    dispatch_semaphore_wait(harvestRequestSemaphore, dispatch_time(DISPATCH_TIME_NOW,  (uint64_t)(post.timeoutInterval*(double)(NSEC_PER_SEC))));
    
    if (error) {
        NRLOG_ERROR(@"Failed to retrieve collector response: %@",error);

#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
        @try {
            #endif
        [NRMATaskQueue queue:[[NRMAMetric alloc] initWithName:[NSString stringWithFormat:kNRSupportabilityPrefix@"/Collector/ResponseErrorCodes/%"NRMA_NSI,[error code]]
                                   value:@1
                               scope:@""]];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
        } @catch (NSException* exception) {
            [NRMAExceptionHandler logException:exception
                                       class:NSStringFromClass([self class])
                                    selector:NSStringFromSelector(_cmd)];
        }
        #endif
        harvestResponse.error = error;
    }
    harvestResponse.statusCode = (int)response.statusCode;
    harvestResponse.responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return harvestResponse;
}

- (NRMAHarvestResponse*) sendConnect
{
    if (self.connectionInformation == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:nil userInfo:nil];
    }
    NSError* error=nil;
    NSData* jsonData = [NRMAJSON dataWithJSONABLEObject:self.connectionInformation options:0 error:&error];
    if (error) {
        NRLOG_ERROR(@"Failed to generate JSON");
        return  nil;
    }
    NSURLRequest* post = [self createConnectPost:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
    if (post == nil) {
        NRLOG_ERROR(@"Failed to create connect POST");
        return nil;
    }
    return [self send:post];
}

- (NRMAConnectInformation*) connectionInformation {
    return _connectionInformation;
}

- (void) setConnectionInformation:(NRMAConnectInformation *)connectionInformation {
    _connectionInformation = connectionInformation;
    self.applicationVersion = connectionInformation.applicationInformation.appVersion;
}

- (NRMAHarvestResponse*) sendData:(NRMAHarvestable *)harvestable
{
    if (harvestable == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:nil
                                     userInfo:nil];
    }
    NSError* error = nil;
    NSData* jsonData = [NRMAJSON dataWithJSONABLEObject:harvestable options:0 error:&error];
    if (error) {
        NRLOG_ERROR(@"Failed to generate JSON");
        return nil;
    }
    NSURLRequest* post = [self createDataPost:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
    if (post == nil) {
        NRLOG_ERROR(@"Failed to create data POST");
        return nil;
    }
    return [self send:post];
}

- (NSURLRequest*) createConnectPost:(NSString *)message
{
    return [self createPostWithURI:[self collectorConnectURL] message:message];
}

- (NSURLRequest*) createDataPost:(NSString *)message
{
    return [self createPostWithURI:[self collectorHostDataURL] message:message];
}
- (NSString*) collectorConnectURL
{
    return [self collectorHostURL:(NSString*)kCOLLECTOR_CONNECT_URI];
}

- (NSString*) collectorHostDataURL
{
    return [self collectorHostURL:(NSString*)kCOLLECTOR_DATA_URL];
}

- (NSString*) collectorHostURL:(NSString*)resource
{
    NSString* protocol = self.useSSL ? @"https://":@"http://";
    return [NSString stringWithFormat:@"%@%@%@",protocol,self.collectorHost,resource];
}
@end
