//
//  NRMANSURLConnectionTests.m
//  NewRelicAgent
//
//  Created by Jonathan Karon on 11/4/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRNSURLConnectionTests.h"

#import "NRMANSURLConnectionSupport.h"

#warning depricated Tests

@interface NRMANSURLConnectionDelegateBase : NSObject
@property (nonatomic, retain, readwrite) id<NSURLConnectionDelegate> realDelegate;
@property (nonatomic, weak, readwrite) NRMANSURLConnectionSupport *connectionWrapper;
@property (nonatomic, retain, readwrite) NSURLRequest* request;
@property (nonatomic, retain, readonly) NSURLResponse* response;
@property (nonatomic, retain, readonly) NSData* responseData;
@end

@interface NRMANSURLConnectionDelegate : NRMANSURLConnectionDelegateBase

@end

@interface NRMANSURLConnectionTestDownloadDelegate : NSObject <NSURLConnectionDownloadDelegate> {
    @public

    BOOL downloadTriggered;
}
@end


@interface NRMANSURLConnectionSupport (Test)
@property (nonatomic, retain, readwrite) NSURLConnection* connection;
@property (nonatomic, retain, readwrite) NRMANSURLConnectionDelegateBase* proxyDelegate;

- (id)delegate;
@end




@implementation NRMANSURLConnectionTests {
    NSError *_failedWithError;
    NSURLConnection *_finishedConnection;
    BOOL _willSendRequestTriggered;
}

- (void) setUp
{
    [super setUp];

    _failedWithError = nil;
    _finishedConnection = nil;
    _willSendRequestTriggered = NO;
}

- (NSURLRequest *)request
{
    return [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.google.com/"]
                                 cachePolicy:NSURLRequestReloadIgnoringCacheData
                             timeoutInterval:60.0];
}
- (NSURLRequest *)badRequest
{
    return [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.google.c/"]
                                 cachePolicy:NSURLRequestReloadIgnoringCacheData
                             timeoutInterval:60.0];
}

- (void)testConnectionReturnsProxyObject
{
    NSURLConnection *conn = [NSURLConnection connectionWithRequest:[self request] delegate:self];
    STAssertEqualObjects(NSStringFromClass([NRMANSURLConnectionSupport class]),
                         NSStringFromClass([conn class]),
                         @"NSURLConnection should return a NRMANSURLConnectionSupport");

    id delegate = ((NRMANSURLConnectionSupport *)conn).delegate;
    STAssertEqualObjects(delegate, self, @"proxyDelegate's delegate (%p) should equal self (%p)", delegate, self);
}

- (void)testConnectionHasConnectionDelegate
{
    NSURLConnection *conn = [NSURLConnection connectionWithRequest:[self request] delegate:self];
    STAssertEqualObjects(NSStringFromClass([NRMANSURLConnectionSupport class]),
                         NSStringFromClass([conn class]),
                         @"NSURLConnection should return a NRMANSURLConnectionSupport");


    NRMANSURLConnectionDelegateBase *proxyDelegate = ((NRMANSURLConnectionSupport *)conn).proxyDelegate;
    STAssertEqualObjects(self, proxyDelegate.realDelegate, @"proxyDelegate's delegate (%p) should equal self (%p)", proxyDelegate.realDelegate, self);
}

- (void)testConnectionHandlesCancel
{
    NSURLConnection *conn = [NSURLConnection connectionWithRequest:[self request] delegate:self];
    [conn start];

    [conn cancel];
    // TODO figure out how to make this work... cancel is not triggering didFailWithError:
//    ConditionalBlock cb = ^{
//        if (_failedWithError) return YES;
//        return NO;
//    };
//    [self waitForCondition:cb withTimeout:5];
    NSLog(@"%@", _failedWithError);
}


- (void)testConnectionTriggersDelegateMessageOnError
{
    _failedWithError = nil;
    [NSURLConnection connectionWithRequest:[self badRequest] delegate:self];

    ConditionalBlock cb = ^{
        if (_failedWithError) return YES;
        return NO;
    };

    [self waitForCondition:cb withTimeout:5];

    STAssertTrue(_failedWithError != nil, @"connection:didFailWithError: did not trigger");
}

- (void)testConnectionTriggersDelegateMessageOnCompletion
{
    _finishedConnection = nil;
    [NSURLConnection connectionWithRequest:[self request] delegate:self];

    ConditionalBlock cb = ^{
        if (_finishedConnection) return YES;
        return NO;
    };

    [self waitForCondition:cb withTimeout:5];

    STAssertTrue(_finishedConnection != nil, @"connectionDidFinishLoading: did not trigger");
}

- (void)testDataDelegateDoesntRespondToDownload
{
    NSURLConnection *conn = [NSURLConnection connectionWithRequest:[self request] delegate:self];
    id<NSObject> delegate = ((NRMANSURLConnectionSupport *)conn).delegate;
    STAssertFalse([delegate respondsToSelector:@selector(connectionDidFinishDownloading:destinationURL:)],
                  @"Proxied NSURLConnectionDataDelegate shoudl not respond to NSURLConnectionDownloadDelegate messages");
}

- (void)testDownloadDelegateRespondsToDownload
{
    NRMANSURLConnectionTestDownloadDelegate *delegate = [[NRMANSURLConnectionTestDownloadDelegate alloc] init];

    STAssertTrue([delegate respondsToSelector:@selector(connectionDidFinishDownloading:destinationURL:)],
                 @"DownloadDelegate should respond to connectionDidFinishDownloading:destinationURL:");

    STAssertFalse(delegate->downloadTriggered, @"DELEGATE SHOULD BE FALSE NOW");
    
    [NSURLConnection connectionWithRequest:[self request] delegate:delegate];

    ConditionalBlock cb = ^{
        if (delegate->downloadTriggered) return YES;
        return NO;
    };

    [self waitForCondition:cb withTimeout:5];

}

#pragma mark NSURLConnectionDataDelegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    _failedWithError = error;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    _finishedConnection = connection;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{

}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{

}

- (void)connection:(NSURLConnection *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{

}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    _willSendRequestTriggered = YES;
    return request;
}



@end


@implementation NRMANSURLConnectionTestDownloadDelegate

- (void)connectionDidFinishDownloading:(NSURLConnection *)connection destinationURL:(NSURL *)destinationURL
{
    downloadTriggered = YES;
}

@end


