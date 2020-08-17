//
//  0Tests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/1/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAURLSessionOverride.h"
#import "NewRelicAgentInternal.h"
#import "NRMAURLSessionTaskOverride.h"
#import "NRMANSURLConnectionSupport+private.h"
#import "NRMANetworkFacade.h"
#import <OCMock/OCMock.h>
#import <objc/runtime.h>
@interface NRMAURLSessionTaskOverrideTests : XCTestCase
@property(strong) NSURLSession* session;
- (BOOL) verifyTaskSwizzled:(NSURLSessionTask*)task;
@end

@implementation NRMAURLSessionTaskOverrideTests

- (void)setUp
{
    [super setUp];
    [NRMAURLSessionOverride beginInstrumentation];
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

- (void)tearDown
{
    [NRMAURLSessionOverride deinstrument];
    [super tearDown];
}

- (BOOL) verifyTaskSwizzled:(NSURLSessionTask*)task
{
    Method method = class_getInstanceMethod([task class], @selector(resume));
    IMP imp = method_getImplementation(method);

    return (imp == (IMP)NRMAOverride__resume);
}

- (void) testTimerCreationAndTaskCompletion
{
    __block BOOL finished = NO;
    id nrMock = [OCMockObject mockForClass:[NRMANetworkFacade class]];
    __block NRTimer* timer;
    [[[[[nrMock expect] ignoringNonObjectArgs] classMethod] andDo:^(NSInvocation* inv) {
        __autoreleasing NRTimer* localTimer;
        [inv getArgument:&localTimer
                 atIndex:4];
        timer = localTimer;
        [inv invoke];
        finished = YES;
    }] noticeNetworkRequest:OCMOCK_ANY
                   response:OCMOCK_ANY
                  withTimer:OCMOCK_ANY
                  bytesSent:0
              bytesReceived:0
               responseData:OCMOCK_ANY
                     params:OCMOCK_ANY];


    __block NSURLSessionDataTask* task = [self.session dataTaskWithURL:[NSURL URLWithString:@"http://google.com"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NRTimer* timer = NRMA__getTimerForSessionTask(task);
        XCTAssertNotNil(timer, @"timer was not set for task!");

    }];

    XCTAssertTrue([self verifyTaskSwizzled:task],@"task's method 'resume' was not instrumented!");

    [task resume];
    while (CFRunLoopGetCurrent() && !finished) {}
    XCTAssertTrue([timer timeElapsedInMilliSeconds] > 0, @"timer was never stopped");
    [nrMock stopMocking];
}

- (void) testRecordNetworkActivity
{

    NSString* url = @"http://google.com";
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

}] noticeResponse:OCMOCK_ANY
 forRequest:OCMOCK_ANY
 withTimer:OCMOCK_ANY
 andBody:OCMOCK_ANY
 bytesSent:0
 bytesReceived:0];

    __block BOOL finished = NO;
    task = [self.session dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        finished = YES;
    }];


    XCTAssertTrue([self verifyTaskSwizzled:task],@"task's method 'resume' was not instrumented!");
    [task resume];

    while (CFRunLoopGetCurrent() && !finished) {}

    XCTAssertNoThrow([mockURLConnectionSupport verify], @"NoticeRepsonse was not called!");
    [mockURLConnectionSupport stopMocking];
}


- (void) testRecordNetworkFailure
{
    NSLog(@"did this (^) test hang? do you have charles running? ಠ_ಠ");
    NSString* badURL = @"http://googleq34.colm";
    id mockURLConnectionSupport = [OCMockObject mockForClass:[NRMANSURLConnectionSupport class]];

     __block NSURLSessionDataTask* task = nil;
    __block BOOL finished = NO;
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


    task = [self.session dataTaskWithURL:[NSURL URLWithString:badURL] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

    }];


    XCTAssertTrue([self verifyTaskSwizzled:task],@"task's method 'resume' was not instrumented!");
    [task resume];

    while (CFRunLoopGetCurrent() && !finished) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }

    XCTAssertNoThrow([mockURLConnectionSupport verify], @"NoticeRepsonse was not called!");
    [mockURLConnectionSupport stopMocking];
}



- (void) testUploadTaskFailure
{
    NSString* badURL = @"http://googleq34.colm";
    id mockURLConnectionSupport = [OCMockObject mockForClass:[NRMANSURLConnectionSupport class]];

    __block NSURLSessionUploadTask* task = nil;

    [[[[[mockURLConnectionSupport expect] ignoringNonObjectArgs] classMethod] andDo:^(NSInvocation *inv) {
        //        //verify some of the values!
        __autoreleasing NSURLRequest* request = nil;
        [inv getArgument:&request atIndex:3];
        XCTAssertTrue([request.URL.absoluteString isEqualToString:badURL], @"url does not match!");

        __autoreleasing NSError* error;
        [inv getArgument:&error atIndex:2];
        XCTAssertTrue(error.code == -1003, @"error \"%ld\" does not match. should be \"host name could not be found\"",(long)error.code);
        __autoreleasing NRTimer* timer;
        [inv getArgument:&timer atIndex:4];
        NRTimer* originalTimer = NRMA__getTimerForSessionTask(task);
        XCTAssertTrue(timer == originalTimer, @"timers do not match!");
        request = nil;
    }] noticeError:OCMOCK_ANY forRequest:OCMOCK_ANY withTimer:OCMOCK_ANY];

    __block BOOL finished = NO;
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:badURL]];
    task = [self.session uploadTaskWithRequest:request
                                      fromData:[@"hello world" dataUsingEncoding:NSUTF8StringEncoding]
                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                 finished = YES;
                             }];


    XCTAssertTrue([self verifyTaskSwizzled:task],@"task's method 'resume' was not instrumented!");
    [task resume];

    while (CFRunLoopGetCurrent() && !finished) {
    }

    XCTAssertNoThrow([mockURLConnectionSupport verify], @"NoticeRepsonse was not called!");
    [mockURLConnectionSupport stopMocking];
}

- (void) testRecordUploadTask
{

    NSString* url = @"http://google.com";
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

    }] noticeResponse:OCMOCK_ANY
     forRequest:OCMOCK_ANY
     withTimer:OCMOCK_ANY
     andBody:OCMOCK_ANY
     bytesSent:0
     bytesReceived:0];

    __block BOOL finished = NO;
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    task = [self.session uploadTaskWithRequest:request
                                      fromData:[NSData new]
                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                 finished = YES;
                             }];


    XCTAssertTrue([self verifyTaskSwizzled:task],@"task's method 'resume' was not instrumented!");
    [task resume];

    while (CFRunLoopGetCurrent() && !finished) {}
    
    XCTAssertNoThrow([mockURLConnectionSupport verify], @"NoticeRepsonse was not called!");
    [mockURLConnectionSupport stopMocking];
}

@end
