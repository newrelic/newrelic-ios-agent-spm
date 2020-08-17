//
//  NRMAURLSessionDelegateTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/1/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "NRMAURLSessionTaskDelegate.h"
#import "NRMAURLSessionOverride.h"

@interface NRMAURLSessionDelegateTests : XCTestCase <NSURLSessionDelegate,NSURLSessionTaskDelegate,NSURLSessionDownloadDelegate,NSURLSessionDataDelegate>
@property(strong) NSURLSession* session;
@end

@implementation NRMAURLSessionDelegateTests

- (void)setUp
{
    [super setUp];

    [NRMAURLSessionOverride beginInstrumentation];

    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue currentQueue]];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [NRMAURLSessionOverride deinstrument];
    [super tearDown];
}




- (void) testNSURLSessionDelegateCallbacks
{
    XCTAssertTrue([self.session.delegate isKindOfClass:[NRMAURLSessionTaskDelegate class]], @"session delegate is not what it should be! It is indstead: %@",[self.session.delegate class]);
    OCMockObject* mockSelf = [OCMockObject partialMockForObject:self];
    [[mockSelf expect] URLSession:OCMOCK_ANY
              didReceiveChallenge:OCMOCK_ANY
                completionHandler:OCMOCK_ANY];

    [[mockSelf expect] URLSessionDidFinishEventsForBackgroundURLSession:OCMOCK_ANY];

    [[mockSelf expect] URLSession:OCMOCK_ANY didBecomeInvalidWithError:OCMOCK_ANY];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self.session.delegate URLSession:self.session
                  didReceiveChallenge:nil
                    completionHandler:nil];
    [self.session.delegate URLSessionDidFinishEventsForBackgroundURLSession:self.session];
    [self.session.delegate URLSession:self.session didBecomeInvalidWithError:nil];
#pragma clang diagnostic pop

    XCTAssertNoThrow([mockSelf verify], @"failed to call back one of the delegate methods!");

    [mockSelf stopMocking];
}

- (void) testNSURLDownloadTaskDelegateCallbacks
{
    XCTAssertTrue([self.session.delegate isKindOfClass:[NRMAURLSessionTaskDelegate class]], @"session delegate is not what it should be! It is indstead: %@",[self.session.delegate class]);
    OCMockObject* mockSelf = [OCMockObject partialMockForObject:self];

    [[mockSelf expect] URLSession:OCMOCK_ANY
                     downloadTask:OCMOCK_ANY
        didFinishDownloadingToURL:OCMOCK_ANY];
    [[mockSelf expect] URLSession:OCMOCK_ANY
                     downloadTask:OCMOCK_ANY
                didResumeAtOffset:1
               expectedTotalBytes:1];
    [[mockSelf expect] URLSession:OCMOCK_ANY
                     downloadTask:OCMOCK_ANY
                     didWriteData:0
                totalBytesWritten:0
        totalBytesExpectedToWrite:0];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [(id<NSURLSessionDownloadDelegate>)self.session.delegate URLSession:self.session
                         downloadTask:nil
                         didWriteData:0
                    totalBytesWritten:0
            totalBytesExpectedToWrite:0];

     [(id<NSURLSessionDownloadDelegate>)self.session.delegate URLSession:self.session
                          downloadTask:nil
                     didResumeAtOffset:1
                    expectedTotalBytes:1];

    [(id<NSURLSessionDownloadDelegate>)self.session.delegate URLSession:self.session
                                                           downloadTask:nil
                                              didFinishDownloadingToURL:nil];

#pragma clang diagnostic pop
    XCTAssertNoThrow([mockSelf verify], @"failed to callback one of the download delegate methods");
    [mockSelf stopMocking];
}

-(void) testNSURLSessionDataDelegateCallbacks
{
    XCTAssertTrue([self.session.delegate isKindOfClass:[NRMAURLSessionTaskDelegate class]], @"session delegate is not what it should be! It is indstead: %@",[self.session.delegate class]);
    OCMockObject* mockSelf = [OCMockObject partialMockForObject:self];

    [[mockSelf expect] URLSession:OCMOCK_ANY
                         dataTask:OCMOCK_ANY
            didBecomeDownloadTask:OCMOCK_ANY];
    [[mockSelf expect]URLSession:OCMOCK_ANY
                        dataTask:OCMOCK_ANY
                  didReceiveData:OCMOCK_ANY];
    [[mockSelf expect] URLSession:OCMOCK_ANY
                         dataTask:OCMOCK_ANY
               didReceiveResponse:OCMOCK_ANY
                completionHandler:OCMOCK_ANY];
    [[mockSelf expect]  URLSession:OCMOCK_ANY
                          dataTask:OCMOCK_ANY
                 willCacheResponse:OCMOCK_ANY
                 completionHandler:OCMOCK_ANY];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [(id<NSURLSessionDataDelegate>)self.session.delegate URLSession:self.session
                                                           dataTask:nil
                                              didBecomeDownloadTask:nil];
    [(id<NSURLSessionDataDelegate>)self.session.delegate URLSession:self.session
                                                          dataTask:nil
                                                    didReceiveData:nil];
    [(id<NSURLSessionDataDelegate>)self.session.delegate URLSession:self.session
                                                           dataTask:nil
                                                 didReceiveResponse:nil
                                                  completionHandler:nil];
    [(id<NSURLSessionDataDelegate>)self.session.delegate URLSession:self.session
                                                           dataTask:nil
                                                  willCacheResponse:nil
                                                  completionHandler:nil];

    XCTAssertNoThrow([mockSelf verify], @"failed to callback one of the data delegate methods");

    [mockSelf stopMocking];
#pragma clang diagnostic pop

}

- (void) testNSURLSessionTaskDelegate
{
 XCTAssertTrue([self.session.delegate isKindOfClass:[NRMAURLSessionTaskDelegate class]], @"session delegate is not what it should be! It is indstead: %@",[self.session.delegate class]);
    OCMockObject* mockSelf = [OCMockObject partialMockForObject:self];

    [[mockSelf expect] URLSession:OCMOCK_ANY
                             task:OCMOCK_ANY
             didCompleteWithError:OCMOCK_ANY];

    [[mockSelf expect] URLSession:OCMOCK_ANY
                             task:OCMOCK_ANY
              didReceiveChallenge:OCMOCK_ANY
                completionHandler:OCMOCK_ANY];
    [[mockSelf expect] URLSession:OCMOCK_ANY
                             task:OCMOCK_ANY
                  didSendBodyData:1
                   totalBytesSent:1
         totalBytesExpectedToSend:1];
    [[mockSelf expect] URLSession:OCMOCK_ANY
                             task:OCMOCK_ANY
                needNewBodyStream:OCMOCK_ANY];
    [[mockSelf expect] URLSession:OCMOCK_ANY
                             task:OCMOCK_ANY
       willPerformHTTPRedirection:OCMOCK_ANY
                       newRequest:OCMOCK_ANY
                completionHandler:OCMOCK_ANY];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [(id<NSURLSessionTaskDelegate>)self.session.delegate URLSession:self.session
                                                               task:nil
                                               didCompleteWithError:nil];
    [(id<NSURLSessionTaskDelegate>)self.session.delegate URLSession:self.session
                                                               task:nil
                                                didReceiveChallenge:nil
                                                  completionHandler:nil];
    [(id<NSURLSessionTaskDelegate>)self.session.delegate URLSession:self.session
                                                               task:nil
                                                    didSendBodyData:1
                                                     totalBytesSent:1
                                           totalBytesExpectedToSend:1];
    [(id<NSURLSessionTaskDelegate>)self.session.delegate URLSession:self.session
                                                               task:nil
                                                  needNewBodyStream:nil];
    [(id<NSURLSessionTaskDelegate>)self.session.delegate URLSession:self.session
                                                               task:nil
                                         willPerformHTTPRedirection:nil
                                                         newRequest:nil
                                                  completionHandler:nil];

#pragma clang diagnostic pop
    XCTAssertNoThrow([mockSelf verify],@"failed to callback task delegate methods");

    [mockSelf stopMocking];


}
//session delegate
- (void) URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {}
- (void) URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {}
- (void) URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {}

//download delegate

- (void) URLSession:(NSURLSession*)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{}
- (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{}
- (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes{}

//task delegate
- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{}
- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler{}
- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{}
- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *))completionHandler{}
- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler{}

//data task delegate
- (void) URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask{}
- (void) URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{}
- (void) URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{}
- (void) URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *))completionHandler{}
@end
