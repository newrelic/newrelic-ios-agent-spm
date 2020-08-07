//
// Created by Bryce Buchanan on 7/7/17.
// Copyright (c) 2017 New Relic. All rights reserved.
//

#import "NRMAHexBackgroundUploader.h"
#import "NRMASessionIdentifierManager.h"

@interface NRMAHexBackgroundUploader ()
@property(strong) NRMASessionIdentifierManager* sessionIdManager;
@property(strong) NSURLSession* session;
@end

@implementation NRMAHexBackgroundUploader



- (instancetype) initWithHexHost:(NSString*)hexHost {
    self = [super init];
    if (self) {
        self.sessionIdManager = [[[NRMASessionIdentifierManager alloc] init] autorelease];
        NSURLSessionConfiguration* backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[self.sessionIdManager sessionIdentifier]];
        self.session = [NSURLSession sessionWithConfiguration:backgroundConfiguration
                                                delegate:self
                                           delegateQueue:[NSOperationQueue currentQueue]];
        self.hexHost = hexHost;
    }
    return self;
}



- (void) sendData:(NSData*)data {

    NSMutableURLRequest* request = [self newPostWithURI:self.hexHost];
    request.HTTPMethod = @"POST";
    request.HTTPBody = data;

    [request setValue:@"application/octet-stream"
   forHTTPHeaderField:@"Content-Type"];
    NSURLSessionUploadTask* uploadTask = [self.session uploadTaskWithStreamedRequest:request];
    [uploadTask resume];
}

- (void) dealloc {
    [self.session invalidateAndCancel];
    self.session = nil;
    self.hexHost = nil;
    self.sessionIdManager = nil;
    [super dealloc];
}



@end
