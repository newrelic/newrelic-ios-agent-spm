//
//  NRMAURLSessionTaskOverrideWithDelegateTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/1/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAURLSessionOverride.h"
#import "NRTimer.h"
#import "NRMAURLSessionTaskOverride.h"
#import "NRMAURLSessionTaskDelegate.h"
#import "NRMANSURLConnectionSupport+private.h"
#import <OCMock/OCMock.h>

@interface NRMAURLSessionTaskOverrideWithDelegateTest : XCTestCase <NSURLSessionDataDelegate>
@property(strong) NSURLSession* session;
@property(strong) NSOperationQueue* myqueue;
@end

@implementation NRMAURLSessionTaskOverrideWithDelegateTest

- (void)setUp
{
    [super setUp];
    self.myqueue = [[NSOperationQueue alloc] init];
    [NRMAURLSessionOverride beginInstrumentation];
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.myqueue];
}

- (void)tearDown
{
    [NRMAURLSessionOverride deinstrument];
    [super tearDown];
}

- (void) testVerifyIsKindOfClass {
    id delegate = self.session.delegate;

    XCTAssertTrue([delegate isKindOfClass:[self class]]);
    XCTAssertTrue([delegate isKindOfClass:[NRMAURLSessionTaskDelegate class]]);
    XCTAssertTrue([delegate respondsToSelector:@selector(testVerifyIsKindOfClass)]);
    XCTAssertFalse([delegate isKindOfClass:[NSDictionary class]]);
}

- (void) testRecordNetworkActivity
{

    NSString* url = @"http://google.com";
    __block BOOL finished = NO;
    id mockURLConnectionSupport = [OCMockObject mockForClass:[NRMANSURLConnectionSupport class]];
    __block NSURLSessionDataTask* task = nil;
    [[[[[mockURLConnectionSupport expect] ignoringNonObjectArgs] classMethod] andDo:^(NSInvocation *inv) {

        __autoreleasing NSURLResponse* response;
        [inv getArgument:&response atIndex:2];
        XCTAssertTrue(response == task.response, @"responses didn't match!");

        __autoreleasing NSURLRequest* request;
        [inv getArgument:&request atIndex:3];
        XCTAssertTrue([request.URL.absoluteString isEqualToString:url], @"url doesn't match!");

        __autoreleasing NRTimer* timer = nil;
        [inv getArgument:&timer atIndex:4];

        NSUInteger bytesSent;
        [inv getArgument:&bytesSent atIndex:6];
        XCTAssertTrue(bytesSent == task.countOfBytesSent, @"bytes sent don't match!");

        NSUInteger bytesReceived;
        [inv getArgument:&bytesReceived atIndex:7];
        XCTAssertTrue(bytesReceived == task.countOfBytesReceived, @"bytes received don't match!");

        XCTAssertTrue(timer == NRMA__getTimerForSessionTask(task), @"timers don't match!");
        finished =YES;

    }] noticeResponse:OCMOCK_ANY
     forRequest:OCMOCK_ANY
     withTimer:OCMOCK_ANY
     andBody:OCMOCK_ANY
     bytesSent:0
     bytesReceived:0];


    task = [self.session dataTaskWithURL:[NSURL URLWithString:url]];


    [task resume];

    while (CFRunLoopGetCurrent() && !finished) {
    }
    
    XCTAssertNoThrow([mockURLConnectionSupport verify], @"NoticeRepsonse was not called!");
    [mockURLConnectionSupport stopMocking];
}

- (void) testRecordNetworkFailure
{

    __block BOOL finished = NO;
    NSString* badURL = @"http://googleq34.colm";
    id mockURLConnectionSupport = [OCMockObject mockForClass:[NRMANSURLConnectionSupport class]];

    __block NSURLSessionDataTask* task = nil;

    [[[[[mockURLConnectionSupport expect] ignoringNonObjectArgs] classMethod] andDo:^(NSInvocation *inv) {
        //        //verify some of the values!
        __autoreleasing NSURLRequest* request = nil;
        [inv getArgument:&request atIndex:3];
        XCTAssertTrue([request.URL.absoluteString isEqualToString:badURL], @"url does not match!");

        __autoreleasing NSError* error;
        [inv getArgument:&error atIndex:2];
        XCTAssertTrue(error.code == -1003, @"the error does not match. should be \"host name could not be found\"");
        __autoreleasing NRTimer* timer;
        [inv getArgument:&timer atIndex:4];
        NRTimer* originalTimer = NRMA__getTimerForSessionTask(task);
        XCTAssertTrue(timer == originalTimer, @"timers do not match!");
        request = nil;
        finished = YES;
    }] noticeError:OCMOCK_ANY forRequest:OCMOCK_ANY withTimer:OCMOCK_ANY];


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    task = [self.session dataTaskWithURL:[NSURL URLWithString:badURL] completionHandler:nil];
#pragma clang diagnostic pop


    [task resume];

    while (CFRunLoopGetCurrent() && !finished) {
    }

    XCTAssertNoThrow([mockURLConnectionSupport verify], @"NoticeRepsonse was not called!");
    [mockURLConnectionSupport stopMocking];
}


- (void) testErrorRecordOnlyOnce
{
    __block BOOL finished = NO;
    NSString* badURL = @"http://googleq34.colm";
    id mockURLConnectionSupport = [OCMockObject mockForClass:[NRMANSURLConnectionSupport class]];

    __block int callCount = 0;
    [[[[[mockURLConnectionSupport expect] ignoringNonObjectArgs] classMethod] andDo:^(NSInvocation *inv) {
        //        //verify some of the values!
        callCount++;
    }]
     noticeError:OCMOCK_ANY
     forRequest:OCMOCK_ANY
     withTimer:OCMOCK_ANY];

    NSURLSessionDataTask* task = nil;
    task = [self.session dataTaskWithURL:[NSURL URLWithString:badURL] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //despite having a delegate, this method should be called.
        finished = YES;
    }];

    [task resume]; //start task

    while (CFRunLoopGetCurrent() && !finished) {
    }

    XCTAssertNoThrow([mockURLConnectionSupport verify], @"NoticeRepsonse was not called!");
    [mockURLConnectionSupport stopMocking];

    XCTAssertTrue(callCount == 1, @"notice error was called more than once. It should only have been called once!");
}

- (void) testSuccessRecordOnlyOnce
{
    NSString* url = @"http://google.com";
    __block BOOL finished = NO;
    id mockURLConnectionSupport = [OCMockObject mockForClass:[NRMANSURLConnectionSupport class]];
    __block int callCount = 0;
    [[[[[mockURLConnectionSupport expect] ignoringNonObjectArgs] classMethod] andDo:^(NSInvocation *inv) {
        callCount++;
    }]
     noticeResponse:OCMOCK_ANY
     forRequest:OCMOCK_ANY
     withTimer:OCMOCK_ANY
     andBody:OCMOCK_ANY
     bytesSent:0
     bytesReceived:0];
    
    NSURLSessionDataTask* task = nil;
    task = [self.session dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //despite having a delegate, this method should be called.
        finished = YES;
    }];
    
    
    [task resume]; //start task

    while (CFRunLoopGetCurrent() && !finished) {
    }
    
    XCTAssertNoThrow([mockURLConnectionSupport verify], @"NoticeRepsonse was not called!");
    [mockURLConnectionSupport stopMocking];
    XCTAssertTrue(callCount == 1, @"notice request was called more than once. It should only have been called once!");
}
@end
