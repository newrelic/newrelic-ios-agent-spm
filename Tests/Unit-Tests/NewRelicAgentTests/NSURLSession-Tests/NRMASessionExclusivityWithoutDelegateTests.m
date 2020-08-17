//
//  NRMASessionExclusivityWithoutDelegateTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/5/15.
//  Copyright (c) 2015 New Relic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "NRMAURLSessionOverride.h"
#import "NRMANetworkFacade.h"
#import "NewRelicAgentInternal.h"
@interface NRMASessionExclusivityWithoutDelegateTests : XCTestCase <NSURLSessionDelegate,NSURLSessionDataDelegate,NSURLSessionTaskDelegate>
@property(strong) id mockSession;
@property(strong) id mockNetwork;
@property(strong) NSOperationQueue* queue;
@property(nonatomic) BOOL networkFinished;
@end

@implementation NRMASessionExclusivityWithoutDelegateTests

- (void)setUp {
    [super setUp];
    [NRMAURLSessionOverride beginInstrumentation];

    self.queue = [[NSOperationQueue alloc] init];
//    self.queue = [NSOperationQueue
    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    self.mockSession = [OCMockObject partialMockForObject:session];
    self.networkFinished = NO;
    self.mockNetwork = [OCMockObject mockForClass:[NRMANetworkFacade class]];
    [[[[[self.mockNetwork expect] ignoringNonObjectArgs] classMethod] andDo:^(NSInvocation* invoke) {
        if (self.networkFinished == YES) {
            XCTFail(@"called notice network request too many times!");
        }
        self.networkFinished = YES;
    }] noticeNetworkRequest:OCMOCK_ANY
                   response:OCMOCK_ANY
                  withTimer:OCMOCK_ANY
                  bytesSent:0
              bytesReceived:0
               responseData:OCMOCK_ANY
                     params:OCMOCK_ANY];
}

- (void)tearDown {
    [self.mockSession stopMocking];
    [self.mockNetwork stopMocking];
    [NRMAURLSessionOverride deinstrument];

    [super tearDown];
}


//TODO: reimplement when NSURLSession instrumentation improved.
- (void) testDataTaskWithRequest {

//
//    [[[self.mockSession expect] andForwardToRealObject] dataTaskWithRequest:OCMOCK_ANY];
//    [[self.mockSession reject]  dataTaskWithURL:OCMOCK_ANY];
//    [[[self.mockSession expect] andForwardToRealObject] dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];
//    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY];
//    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY completionHandler:OCMOCK_ANY];
//    [[self.mockSession reject] uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY];
//    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY completionHandler:OCMOCK_ANY];
//    [[self.mockSession reject]  uploadTaskWithStreamedRequest:OCMOCK_ANY];
//    NSURLSessionDataTask* task = [self.mockSession dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"www.google.com"]]];
//    [task resume];
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        self.networkFinished = YES;
//    });
//
//    while (CFRunLoopGetMain() && !self.networkFinished) {}
//
//    XCTAssertNoThrow([self.mockNetwork verify], @"did not capture network data");
//     XCTAssertNoThrow([self.mockSession verify],@"a method that should have been called, was.");
}


- (void) testDataTaskWithURLCompeltionHandler {


    [[self.mockSession reject]  dataTaskWithRequest:OCMOCK_ANY];
    if( @available(iOS 13, *)) {
        [[[self.mockSession reject] andForwardToRealObject] dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    } else if (@available(iOS 12,*)) {
        [[[self.mockSession expect] andForwardToRealObject] dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    }
    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithStreamedRequest:OCMOCK_ANY];
    NSURLSessionDataTask* task = [self.mockSession dataTaskWithURL:[NSURL URLWithString:@"https://www.google.com"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

    }];
    [task resume];


     XCTAssertNoThrow([self.mockSession verify],@"a method that shouldn't have been called, was.");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.networkFinished = YES;
    });

    while (CFRunLoopGetCurrent() && !self.networkFinished) {}
    XCTAssertNoThrow([self.mockNetwork verify], @"did not capture network data");
}

//TODO: reimplement when NSURLSession instrumentation improved.
- (void) testDataTaskWithURL {
//
//
//    [[self.mockSession reject]  dataTaskWithRequest:OCMOCK_ANY];
//    [[[self.mockSession expect] andForwardToRealObject] dataTaskWithURL:OCMOCK_ANY];
//    [[[self.mockSession expect] andForwardToRealObject] dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];
//    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY];
//    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY completionHandler:OCMOCK_ANY];
//    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY];
//    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY completionHandler:OCMOCK_ANY];
//    [[self.mockSession reject]  uploadTaskWithStreamedRequest:OCMOCK_ANY];
//    NSURLSessionDataTask* task = [self.mockSession dataTaskWithURL:[NSURL URLWithString:@"www.google.com"]];
//    [task resume];
//
//
//     XCTAssertNoThrow([self.mockSession verify],@"a method that should have been called, was.");
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        self.networkFinished = YES;
//    });
//
//    while (CFRunLoopGetCurrent() && !self.networkFinished) {}
//    XCTAssertNoThrow([self.mockNetwork verify], @"did not capture network data");
}
- (void) testDataTaskWithRequestCompletionHandler {


    [[self.mockSession reject]  dataTaskWithRequest:OCMOCK_ANY];
    [[self.mockSession reject]  dataTaskWithURL:OCMOCK_ANY];
    [[[self.mockSession expect] andForwardToRealObject] dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithStreamedRequest:OCMOCK_ANY];
    NSURLSessionDataTask* task = [self.mockSession dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.google.com"]] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

    }];

    [task resume];

     XCTAssertNoThrow([self.mockSession verify],@"a method that should have been called, was.");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.networkFinished = YES;
    });

    while (CFRunLoopGetCurrent() && !self.networkFinished) {}
    XCTAssertNoThrow([self.mockNetwork verify], @"did not capture network data");
}
//TODO: reimplement when NSURLSession instrumentation improved.
- (void) testUploadTaskWithRequestFromData {
//
//
//    [[[self.mockSession reject] andForwardToRealObject] dataTaskWithRequest:OCMOCK_ANY];
//    [[[self.mockSession reject] andForwardToRealObject] dataTaskWithURL:OCMOCK_ANY];
//    [[[self.mockSession reject] andForwardToRealObject] dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];
//    [[[self.mockSession expect] andForwardToRealObject] uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY];
//    [[[self.mockSession reject] andForwardToRealObject] uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY completionHandler:OCMOCK_ANY];
//    [[[self.mockSession reject] andForwardToRealObject] uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY];
//    [[[self.mockSession reject] andForwardToRealObject] uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY completionHandler:OCMOCK_ANY];
//    [[[self.mockSession reject] andForwardToRealObject] uploadTaskWithStreamedRequest:OCMOCK_ANY];
//
//
//    NSURLSessionUploadTask* task = [self.mockSession uploadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com"]] fromData:[@"asdf" dataUsingEncoding:NSUTF8StringEncoding]];
//    [task resume];
//
//     XCTAssertNoThrow([self.mockSession verify],@"a method that should have been called, was.");
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        self.networkFinished = YES;
//    });
//
//    while (CFRunLoopGetCurrent() && !self.networkFinished) {}
//    XCTAssertNoThrow([self.mockNetwork verify], @"did not capture network data");
}


//TODO: reimplement when NSURLSession instrumentation improved.
- (void) testUploadTaskWithRequestFromFile {

//    [[self.mockSession reject]  dataTaskWithRequest:OCMOCK_ANY];
//    [[self.mockSession reject]  dataTaskWithURL:OCMOCK_ANY];
//    [[self.mockSession reject]  dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];
//
//    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY];
//
//    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY completionHandler:OCMOCK_ANY];
//    [[[self.mockSession expect] andForwardToRealObject] uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY];
//    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY completionHandler:OCMOCK_ANY];
//    [[self.mockSession reject]  uploadTaskWithStreamedRequest:OCMOCK_ANY];
//
//NSURLSessionUploadTask* task =     [self.mockSession  uploadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com"]] fromFile:[[NSURL alloc] initFileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"JdAWN9v" ofType:@"png"]]];
//
//    [task resume];
//
//
//     XCTAssertNoThrow([self.mockSession verify],@"a method that should have been called, was.");
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        self.networkFinished = YES;
//    });
//
//    while (CFRunLoopGetCurrent() && !self.networkFinished) {}
//    XCTAssertNoThrow([self.mockNetwork verify], @"did not capture network data");
}


//TODO: reimplement when NSURLSession instrumentation improved.
- (void) testUploadTaskWithStreamedRequest {
//
//    [[self.mockSession reject]  dataTaskWithRequest:OCMOCK_ANY];
//    [[self.mockSession reject]  dataTaskWithURL:OCMOCK_ANY];
//    [[self.mockSession reject]  dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];
//
//    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY];
//
//    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY completionHandler:OCMOCK_ANY];
//    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY];
//    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY completionHandler:OCMOCK_ANY];
//    [[[self.mockSession expect] andForwardToRealObject] uploadTaskWithStreamedRequest:OCMOCK_ANY];
//
//    NSURLSessionUploadTask* task = [self.mockSession uploadTaskWithStreamedRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://google.com"]]];
//    [task resume];
//
//     XCTAssertNoThrow([self.mockSession verify],@"a method that should have been called, was.");
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        self.networkFinished = YES;
//    });
//
//    while (CFRunLoopGetCurrent() && !self.networkFinished) {}
//    XCTAssertNoThrow([self.mockNetwork verify], @"did not capture network data");
}

/* Sent as the last message related to a specific task.  Error may be
 * nil, which implies that no error occurred and this task is complete.
 */
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {

}
@end
