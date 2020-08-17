//
//  NRMAURLSessionNetworkErrorTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 7/13/16.
//  Copyright © 2016 New Relic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "NRMAURLSessionOverride.h"
#import "NewRelicAgentInternal.h"
#import "NRMANetworkFacade.h"
@interface NRMAURLSessionNetworkErrorTests : XCTestCase <NSURLSessionDelegate,NSURLSessionDataDelegate,NSURLSessionTaskDelegate>
@property(strong) id mockSession;
@property(strong) id mockNetwork;
@property(strong) NSOperationQueue* queue;
@property(nonatomic) BOOL networkFinished;
@end

@implementation NRMAURLSessionNetworkErrorTests

- (void)setUp {
    [super setUp];
    [NRMAURLSessionOverride beginInstrumentation];

    self.queue = [[NSOperationQueue alloc] init];
    //    self.queue = [NSOperationQueue
    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.queue];
    self.mockSession = [OCMockObject partialMockForObject:session];
    self.networkFinished = NO;
    self.mockNetwork = [OCMockObject mockForClass:[NRMANetworkFacade class]];
    [[[[[[self.mockNetwork expect] ignoringNonObjectArgs] classMethod] andDo:^(NSInvocation* invoke) {
        if (self.networkFinished == YES) {
            XCTFail(@"called notice network request too many times!");
        }
        self.networkFinished = YES;
    }] ignoringNonObjectArgs] noticeNetworkFailure:OCMOCK_ANY
                                         withTimer:OCMOCK_ANY
                                         withError:OCMOCK_ANY];
}

- (void)tearDown {
    [self.mockSession stopMocking];
    [self.mockNetwork stopMocking];
    [NRMAURLSessionOverride deinstrument];

    [super tearDown];
}


- (void) testDataTaskWithRequest {


    [[[self.mockSession expect] andForwardToRealObject] dataTaskWithRequest:OCMOCK_ANY];
    [[self.mockSession reject]  dataTaskWithURL:OCMOCK_ANY];
    if( @available(iOS 13, *)) {
        [[[self.mockSession reject] andForwardToRealObject] dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    } else if (@available(iOS 12,*)) {
        [[[self.mockSession expect] andForwardToRealObject] dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    }
    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[self.mockSession reject] uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithStreamedRequest:OCMOCK_ANY];

    //this is an ill-formed url and will cause a network error
    NSURLSessionDataTask* task = [self.mockSession dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"www.google.com"]]];
    [task resume];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.networkFinished = YES;
    });

    while (CFRunLoopGetMain() && !self.networkFinished) {}

    XCTAssertNoThrow([self.mockNetwork verify], @"did not capture network data");
    XCTAssertNoThrow([self.mockSession verify],@"a method that should have been called, was.");
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

    //this is an ill-formed url and will cause a network error
    NSURLSessionDataTask* task = [self.mockSession dataTaskWithURL:[NSURL URLWithString:@"www.google.com"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

    }];
    [task resume];


    XCTAssertNoThrow([self.mockSession verify],@"a method that should have been called, was.");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.networkFinished = YES;
    });

    while (CFRunLoopGetCurrent() && !self.networkFinished) {}
    XCTAssertNoThrow([self.mockNetwork verify], @"did not capture network data");
}
- (void) testDataTaskWithURL {


    [[self.mockSession reject]  dataTaskWithRequest:OCMOCK_ANY];
    [[[self.mockSession expect] andForwardToRealObject] dataTaskWithURL:OCMOCK_ANY];
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

    //this is an ill-formed url and will cause a network error
    NSURLSessionDataTask* task = [self.mockSession dataTaskWithURL:[NSURL URLWithString:@"www.google.com"]];
    [task resume];


    XCTAssertNoThrow([self.mockSession verify],@"a method that should have been called, was.");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.networkFinished = YES;
    });

    while (CFRunLoopGetCurrent() && !self.networkFinished) {}
    XCTAssertNoThrow([self.mockNetwork verify], @"did not capture network data");
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
    NSURLSessionDataTask* task = [self.mockSession dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"www.google.com"]] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

    }];

    [task resume];

    XCTAssertNoThrow([self.mockSession verify],@"a method that should have been called, was.");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.networkFinished = YES;
    });

    while (CFRunLoopGetCurrent() && !self.networkFinished) {}
    XCTAssertNoThrow([self.mockNetwork verify], @"did not capture network data");
}

- (void) testUploadTaskWithRequestFromData {


    [[[self.mockSession reject] andForwardToRealObject] dataTaskWithRequest:OCMOCK_ANY];
    [[[self.mockSession reject] andForwardToRealObject] dataTaskWithURL:OCMOCK_ANY];
    [[[self.mockSession reject] andForwardToRealObject] dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[[self.mockSession expect] andForwardToRealObject] uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY];
    [[[self.mockSession reject] andForwardToRealObject] uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[[self.mockSession reject] andForwardToRealObject] uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY];
    [[[self.mockSession reject] andForwardToRealObject] uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[[self.mockSession reject] andForwardToRealObject] uploadTaskWithStreamedRequest:OCMOCK_ANY];


    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.imgur.com/3/image"]];
    [request addValue:@"Client-ID 3e81eb4ece83db7" forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"POST"];
    NSURL* imgURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"JdAWN9v" withExtension:@"png"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    (void)[NSData dataWithContentsOfFile:imgURL.path];

    NSURLSessionUploadTask* task = [self.mockSession uploadTaskWithRequest:request
                                                                  fromData:nil];
#pragma clang diagnostic pop
    [task resume];

    XCTAssertNoThrow([self.mockSession verify],@"a method that should have been called, was.");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.networkFinished = YES;
    });

    while (CFRunLoopGetCurrent() && !self.networkFinished) {}
    XCTAssertNoThrow([self.mockNetwork verify], @"did not capture network data");
}

- (void) testUploadTaskWithRequestFromDataCompletionHandler {


    [[self.mockSession reject]  dataTaskWithRequest:OCMOCK_ANY];
    [[self.mockSession reject]  dataTaskWithURL:OCMOCK_ANY];
    [[self.mockSession reject]  dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY];
    [[[self.mockSession expect] andForwardToRealObject] uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithStreamedRequest:OCMOCK_ANY];

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.imgur.com/3/image"]];

    [request addValue:@"Client-ID 3e81eb4ece83db7" forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"POST"];

    NSURL* imgURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"JdAWN9v" withExtension:@"png"];
    (void)[NSData dataWithContentsOfFile:imgURL.path];

    //sending no data will cause a network error
    NSURLSessionUploadTask* task = [self.mockSession uploadTaskWithRequest:request
                                                                  fromData:nil
                                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                         }];

    [task resume];


    XCTAssertNoThrow([self.mockSession verify],@"a method that should have been called, was.");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(65 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^{
        self.networkFinished = YES;
    });

    while (CFRunLoopGetCurrent() && !self.networkFinished) {}
    XCTAssertNoThrow([self.mockNetwork verify], @"did not capture network data");
}
- (void) testUploadTaskWithRequestFromFile {

    [[self.mockSession reject]  dataTaskWithRequest:OCMOCK_ANY];
    [[self.mockSession reject]  dataTaskWithURL:OCMOCK_ANY];
    [[self.mockSession reject]  dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];

    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY];

    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[[self.mockSession expect] andForwardToRealObject] uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithStreamedRequest:OCMOCK_ANY];

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.imgur.m/3/image"]]; //bad url on purpose.

    //removing these key values will cause a network error?
//    [request addValue:@"Client-ID 3e81eb4ece83db7" forHTTPHeaderField:@"Authorization"];
//    [request setHTTPMethod:@"POST"];


    NSURLSessionUploadTask* task = [self.mockSession  uploadTaskWithRequest:request
                                                                   fromFile:[[NSURL alloc] initFileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"JdAWN9v" ofType:@"png"]]];

    [task resume];


    XCTAssertNoThrow([self.mockSession verify],@"a method that should have been called, was.");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(65 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.networkFinished = YES;
    });

    while (CFRunLoopGetCurrent() && !self.networkFinished) {}
    XCTAssertNoThrow([self.mockNetwork verify], @"did not capture network data");
}


- (void) testUploadTaskWithRequestFromFileCompletionHandler {

    [[self.mockSession reject]  dataTaskWithRequest:OCMOCK_ANY];
    [[self.mockSession reject]  dataTaskWithURL:OCMOCK_ANY];
    [[self.mockSession reject]  dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];

    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY];

    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY];
    [[[self.mockSession expect] andForwardToRealObject] uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithStreamedRequest:OCMOCK_ANY];

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.imgur.m/3/image"]]; // bad url on purpose

    [request setTimeoutInterval:2];

    //removing these key values will cause a network error?

    [request addValue:@"Client-ID 3e81eb4ece83db7-false" forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"POST"];

    NSURLSessionUploadTask* task = [self.mockSession  uploadTaskWithRequest:request
                                                                   fromFile:[[NSURL alloc] initFileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"JdAWN9v" ofType:@"png"]]
                                                          completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                          }];

    [task resume];

    XCTAssertNoThrow([self.mockSession verify],@"a method that should have been called, was.");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(65 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.networkFinished = YES;
    });

    while (CFRunLoopGetCurrent() && !self.networkFinished) {}
    XCTAssertNoThrow([self.mockNetwork verify], @"did not capture network data");
}

- (void) testUploadTaskWithStreamedRequest {

    [[self.mockSession reject]  dataTaskWithRequest:OCMOCK_ANY];
    [[self.mockSession reject]  dataTaskWithURL:OCMOCK_ANY];
    [[self.mockSession reject]  dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];

    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY];

    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY];
    [[self.mockSession reject]  uploadTaskWithRequest:OCMOCK_ANY fromFile:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[[self.mockSession expect] andForwardToRealObject] uploadTaskWithStreamedRequest:OCMOCK_ANY];


    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.imgur.m/3/image"]];

//    removing these key values will cause a network error?
//    [request addValue:@"Client-ID 3e81eb4ece83db7" forHTTPHeaderField:@"Authorization"];
//    [request setHTTPMethod:@"POST"];


    NSURLSessionUploadTask* task = [self.mockSession uploadTaskWithStreamedRequest:request];
    [task resume];

    XCTAssertNoThrow([self.mockSession verify],@"a method that should have been called, was.");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.networkFinished = YES;
    });

    while (CFRunLoopGetCurrent() && !self.networkFinished) {}
    XCTAssertNoThrow([self.mockNetwork verify], @"did not capture network data");
}

/* Sent as the last message related to a specific task.  Error may be
 * nil, which implies that no error occurred and this task is complete.
 */
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    
}

@end
