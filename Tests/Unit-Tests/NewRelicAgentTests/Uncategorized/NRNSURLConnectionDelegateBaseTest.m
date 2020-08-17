//
//  NRMANSURLConnectionDelegateBaseTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/23/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMANSURLConnectionSupport.h"
#import "NRMANSURLConnectionDelegate.h"
#import "NRMANSURLConnectionSupport+private.h"
#import "NRMAHarvesterConfiguration.h"
#import "NewRelicAgentInternal.h"
#import "NRMAHarvestController.h"
#import <OCMock/OCMock.h>


@interface NRMANSURLConnectionSupport ()
+ (NRMANSURLConnectionDelegate*) generateProxyFromDelegate:(id<NSURLConnectionDelegate>)realDelegate
                                                 request:(NSMutableURLRequest*)mutableRequest
                                        startImmediately:(BOOL)startImmediately;

+ (void)noticeResponse:(NSURLResponse *)response
            forRequest:(NSURLRequest *)request
             withTimer:(NRTimer *)timer
               andBody:(NSData *)body
             bytesSent:(NSUInteger)sent
         bytesReceived:(NSUInteger)received;

+ (void)noticeError:(NSError*)error forRequest:(NSURLRequest *)request withTimer:(NRTimer *)timer;

@end

@interface NRMANSURLConnectionDelegateBase ()
- (NRTimer*) timer;
@end

@interface TestDataDelegate : NSObject <NSURLConnectionDelegate,NSURLConnectionDataDelegate>
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
- (void)connection:(NSURLConnection *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;
@end

@implementation TestDataDelegate
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    //nop
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    //nop
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //nop
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //nop
}

- (void)connection:(NSURLConnection *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    //nop
}
@end

@interface TestDownloadDelegate : NSObject <NSURLConnectionDelegate,NSURLConnectionDownloadDelegate>
@end

@implementation TestDownloadDelegate

- (void)connection:(NSURLConnection *)connection
      didWriteData:(long long)bytesWritten
 totalBytesWritten:(long long)totalBytesWritten
expectedTotalBytes:(long long)expectedTotalBytes
{

}

- (void) connectionDidResumeDownloading:(NSURLConnection *)connection
                      totalBytesWritten:(long long)totalBytesWritten
                     expectedTotalBytes:(long long)expectedTotalBytes
{

}

- (void) connectionDidFinishDownloading:(NSURLConnection *)connection destinationURL:(NSURL *)destinationURL
{

}
@end

@interface NRMANSURLConnectionDelegateBaseTest : XCTestCase
{
    NRMANSURLConnectionDelegate* proxyDelegate;
    TestDataDelegate* testDelegate;
    NSMutableURLRequest* request;
    id connSupportMock;

}

@end

@implementation NRMANSURLConnectionDelegateBaseTest

- (void)setUp
{
    [super setUp];

    request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://google.com"]];
    testDelegate = [TestDataDelegate new];
    connSupportMock = [OCMockObject mockForClass:[NRMANSURLConnectionSupport class]];
}


- (void) testSuccessfulUpload
{
    NRMAHarvesterConfiguration* config = [[NRMAHarvesterConfiguration alloc] init];
    config.response_body_limit = 3;
    OCMockObject* obj = [OCMockObject mockForClass:[NRMAHarvestController class]];
    [[[obj stub] andReturn:config] configuration];


    NSInteger didSendBodyData = 100000;
    NSURLResponse* response = [NSURLResponse new];
    NSInteger totalBytesWritten = didSendBodyData;
    NSInteger totalBytesExpectedToWrite = didSendBodyData;

    NSData* data = [NSData dataWithBytes:"hello world" length:11];
    proxyDelegate = [NRMANSURLConnectionSupport generateProxyFromDelegate:testDelegate request:request startImmediately:YES];

    id mockDelegate = [OCMockObject partialMockForObject:testDelegate];
    [[mockDelegate expect] connection:OCMOCK_ANY didReceiveResponse:OCMOCK_ANY];
    [[mockDelegate expect] connection:OCMOCK_ANY willCacheResponse:OCMOCK_ANY];
    [[mockDelegate expect] connection:OCMOCK_ANY
                      didSendBodyData:didSendBodyData
                    totalBytesWritten:totalBytesWritten
            totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    [[mockDelegate expect] connection:OCMOCK_ANY didReceiveData:OCMOCK_ANY];
    [[mockDelegate expect] connectionDidFinishLoading:OCMOCK_ANY];


    //verify the expected data is passed to the measurement engine
    [[[connSupportMock expect] andDo:^(NSInvocation *invoc) {
        NSData* responseData = nil;
        [invoc getArgument:&responseData atIndex:5];

        XCTAssertTrue([responseData length] == config.response_body_limit,@"we should limit the size of the response body");
        XCTAssertEqualObjects([[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding], @"hel", @"");

    } ] noticeResponse:response
                                  forRequest:request
                                   withTimer:[proxyDelegate timer]
                                     andBody:OCMOCK_ANY
                                   bytesSent:totalBytesExpectedToWrite
                               bytesReceived:[data length]];


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    //simulate network activity
    [proxyDelegate connection:nil willSendRequest:request redirectResponse:nil];
    [proxyDelegate connection:nil willCacheResponse:nil];//verified un-proxied method is still forwarded to original delegate
    [proxyDelegate connection:nil didSendBodyData:didSendBodyData
            totalBytesWritten:totalBytesWritten
    totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    [proxyDelegate connection:nil didReceiveResponse:response];
    [proxyDelegate connection:nil didReceiveData:data];
    [proxyDelegate connectionDidFinishLoading:nil];

#pragma clang diagnostic pop
    [mockDelegate verify]; //verify all the original delegate methods were called.
    [connSupportMock verify]; //verify expected method was called;
    [obj stopMocking];
    [mockDelegate stopMocking];
}

- (void) testFailedConnection
{

    NSError* error = [NSError errorWithDomain:@"Unknown" code:NSURLErrorCancelled userInfo:nil];

    proxyDelegate = [NRMANSURLConnectionSupport generateProxyFromDelegate:testDelegate request:request startImmediately:YES];

    id mockDelegate = [OCMockObject partialMockForObject:testDelegate];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [[mockDelegate expect] connection:nil didFailWithError:error];

    [[connSupportMock expect] noticeError:error forRequest:request withTimer:[proxyDelegate timer]];

    [proxyDelegate connection:nil willSendRequest:request redirectResponse:nil];

    [proxyDelegate connection:nil didFailWithError:error];
#pragma clang diagnostic pop

    [mockDelegate verify]; //verify all the original delegate methods were called.
    [connSupportMock verify]; //verify expected method was called;

    [mockDelegate stopMocking];

}


- (void) testImpersonation {
    proxyDelegate = [NRMANSURLConnectionSupport generateProxyFromDelegate:testDelegate request:request startImmediately:YES];
    XCTAssertTrue([proxyDelegate isKindOfClass:[NRMANSURLConnectionDelegate class]]);
    XCTAssertTrue([proxyDelegate isKindOfClass:[testDelegate class]]);

}

- (void) testNoData
{
    NSInteger didSendBodyData = 100000;
    NSURLResponse* response = [NSURLResponse new];
    NSInteger totalBytesWritten = didSendBodyData;
    NSInteger totalBytesExpectedToWrite = didSendBodyData;

    proxyDelegate = [NRMANSURLConnectionSupport generateProxyFromDelegate:testDelegate request:request startImmediately:YES];

    id mockDelegate = [OCMockObject partialMockForObject:testDelegate];
    [[mockDelegate expect] connection:OCMOCK_ANY didReceiveResponse:OCMOCK_ANY];
    [[mockDelegate expect] connection:OCMOCK_ANY willCacheResponse:OCMOCK_ANY];
    [[mockDelegate expect] connection:OCMOCK_ANY
                      didSendBodyData:didSendBodyData
                    totalBytesWritten:totalBytesWritten
            totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    [[mockDelegate expect] connection:OCMOCK_ANY didReceiveData:OCMOCK_ANY];
    [[mockDelegate expect] connectionDidFinishLoading:OCMOCK_ANY];


    //verify the expected data is passed to the measurement engine
    [[connSupportMock expect] noticeResponse:response
                                  forRequest:request
                                   withTimer:[proxyDelegate timer]
                                     andBody:OCMOCK_ANY
                                   bytesSent:totalBytesExpectedToWrite
                               bytesReceived:0];


    //simulate network activity

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [proxyDelegate connection:nil willSendRequest:request redirectResponse:nil];
    [proxyDelegate connection:nil willCacheResponse:nil];//verified un-proxied method is still forwarded to original delegate
    [proxyDelegate connection:nil didSendBodyData:didSendBodyData
            totalBytesWritten:totalBytesWritten
    totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    [proxyDelegate connection:nil didReceiveResponse:response];
    [proxyDelegate connection:nil didReceiveData:nil]; //if there is nil data this delegate method probably wont be called... but lets see anyway.
    [proxyDelegate connectionDidFinishLoading:nil];
#pragma clang diagnostic pop

    [mockDelegate verify]; //verify all the original delegate methods were called.
    [connSupportMock verify]; //verify expected method was called;

    [mockDelegate stopMocking];
}


- (void) testNoInterfereWithDownloadDelegate
{
    TestDownloadDelegate* downloadDelegate = [[TestDownloadDelegate alloc] init];

    proxyDelegate = [NRMANSURLConnectionSupport generateProxyFromDelegate:downloadDelegate request:request startImmediately:YES];



    id mockDelegate = [OCMockObject partialMockForObject:downloadDelegate];

    [[mockDelegate expect] connectionDidResumeDownloading:OCMOCK_ANY totalBytesWritten:0 expectedTotalBytes:0];
    [[mockDelegate expect] connectionDidFinishDownloading:OCMOCK_ANY destinationURL:OCMOCK_ANY];
    [[mockDelegate expect] connection:OCMOCK_ANY didWriteData:0 totalBytesWritten:0 expectedTotalBytes:0];

    [[connSupportMock expect] noticeResponse:OCMOCK_ANY
                                  forRequest:OCMOCK_ANY
                                   withTimer:OCMOCK_ANY
                                     andBody:OCMOCK_ANY
                                   bytesSent:0
                               bytesReceived:0];




#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [(id)proxyDelegate connectionDidResumeDownloading:nil totalBytesWritten:0 expectedTotalBytes:0];

    [(id)proxyDelegate connection:nil didWriteData:0 totalBytesWritten:0 expectedTotalBytes:0];

    [(id)proxyDelegate connectionDidFinishDownloading:nil destinationURL:nil];
#pragma clang diagnostic pop

    [mockDelegate verify];

    XCTAssertThrows([connSupportMock verify], @"we shouldn't call notice response");
}


- (void) testNilTimerToNoticeMethods
{
    XCTAssertNoThrow([NRMANSURLConnectionSupport noticeResponse:nil forRequest:nil withTimer:nil andBody:nil bytesSent:0 bytesReceived:0],@"crashed because of nil values");
}



- (void)tearDown
{
    request = nil;
    testDelegate = nil;
    [connSupportMock stopMocking];
    [super tearDown];
}

@end
