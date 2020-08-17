//
//  NRMANSURLConnectionSupportTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/22/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRAgentTestBase.h"
#import "NRMANSURLConnectionDelegateBase.h"
#import "NRMANetworkFacade.h"
#import "NRMANSURLConnectionSupport.h"
#import <objc/runtime.h>
#import <OCMock/OCMock.h>
#import "NRMAHarvestController.h"
#import "NewRelicAgentInternal.h"


@class NRMANSURLConnectionDelegate;
@interface NRMANSURLConnectionSupport ()
+ (IMP*)getIMPArray;
+ (IMP) getNRMA_InitWithReqeust_Delegate_;
+ (IMP) getNRMA_InitWithRequest_Delegate_StartImmediately;
+ (void) set__NRMA__initWithRequest_delegate:(IMP)imp;
+ (void) set__NRMA__initWithRequest_delegate_startImmediately:(IMP)imp;

+ (id) poseImplementationBlockForSelector:(SEL)sel;
@end

@interface NRMANSURLConnectionDelegateBase ()
- (NRTimer*) timer;
@end

@interface NRMANSURLConnectionSupportTests : XCTestCase
{
    Class clazz;

    IMP sendSynchronousRequest_returningResponse_error_;
    IMP sendAsynchronousRequest_queue_completionHandler_;

    IMP initWithRequest_delegate_;
    IMP initWithRequest_delegate_startImmediately;

    id mock;

    BOOL blockOverrideSendSynchronousCalled;
    BOOL blockOverrideSendAsyncCall;
}
@end

@implementation NRMANSURLConnectionSupportTests

- (void)setUp
{
    [super setUp];
    clazz = [NSURLConnection class];
    sendSynchronousRequest_returningResponse_error_ = method_getImplementation(class_getClassMethod(clazz, @selector(sendSynchronousRequest:returningResponse:error:)));
    sendAsynchronousRequest_queue_completionHandler_ = method_getImplementation(class_getClassMethod(clazz, @selector(sendAsynchronousRequest:queue:completionHandler:)));

    initWithRequest_delegate_ = method_getImplementation(class_getInstanceMethod(clazz, @selector(initWithRequest:delegate:)));
    initWithRequest_delegate_startImmediately = method_getImplementation(class_getInstanceMethod(clazz,@selector(initWithRequest:delegate:startImmediately:)));


    blockOverrideSendSynchronousCalled = NO;
    blockOverrideSendAsyncCall  = NO;

    mock = [OCMockObject niceMockForClass:[NRMANSURLConnectionSupport class]];
    [self stubMock];

    [NRMANSURLConnectionSupport instrumentNSURLConnection];
}

- (void) stubMock
{
//    __block BOOL* blah = &blockOverrideSendSynchronousCalled;
    [[[mock stub] andDo:^(NSInvocation *invo) {
      id block = (id)[[^(id _self, NSURLRequest* request, NSURLResponse** response, NSError** error) {
            blockOverrideSendSynchronousCalled = YES;
      }copy]autorelease];
        [invo setReturnValue:(void*)&block];

    }] poseImplementationBlockForSelector:@selector(sendSynchronousRequest:returningResponse:error:)];

    [[[mock stub] andDo:^(NSInvocation *invoc) {
        id block = (id) [[^(id _self, NSURLRequest* request, NSOperationQueue *queue, void (^handler)(NSURLResponse*, NSData*, NSError*)) {
            blockOverrideSendAsyncCall = YES;
        } copy] autorelease];
        [invoc setReturnValue:&block];
    }] poseImplementationBlockForSelector:@selector(sendAsynchronousRequest:queue:completionHandler:)];
}
- (void)tearDown
{

    [mock stopMocking];
    [NRMANSURLConnectionSupport deinstrumentNSURLConnection];
    [super tearDown];
}


- (void) testOverwritten
{
    IMP* origImps = [NRMANSURLConnectionSupport getIMPArray];

    XCTAssertTrue(sendSynchronousRequest_returningResponse_error_ == origImps[0], @"sendSynchronousRequest:returingResponse:error stored IMP doesn't match orginial IMP.");
    XCTAssertTrue(sendAsynchronousRequest_queue_completionHandler_ == origImps[1], @"sendAsynchronousRequest:queue:completionHandler: stored IMP doesn't match orginial IMP.");

    XCTAssertTrue(initWithRequest_delegate_ == [NRMANSURLConnectionSupport getNRMA_InitWithReqeust_Delegate_], @"");
    XCTAssertTrue(initWithRequest_delegate_startImmediately ==  [NRMANSURLConnectionSupport getNRMA_InitWithRequest_Delegate_StartImmediately],@"initWithRequest:delegate:startImmediately stored IMP doesn't match  original IMP.");
}

- (void) testSendSynchronousCalled
{

    XCTAssertFalse(blockOverrideSendSynchronousCalled, @"Verify bool is not set");

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [NSURLConnection sendSynchronousRequest:nil returningResponse:nil error:nil];
#pragma clang diagnostic pop
    XCTAssertTrue(blockOverrideSendSynchronousCalled, @"Verify our override-method block is called");
}

- (void) testSendAsyncCall
{
    XCTAssertFalse(blockOverrideSendAsyncCall, @"Verify bool is not set");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [NSURLConnection sendAsynchronousRequest:nil queue:nil completionHandler:nil];
#pragma clang diagnostic pop
    XCTAssertTrue(blockOverrideSendAsyncCall, @"Verify our override-method block is called");
}


- (void) testInitWithRequest
{
    //fetch ptr to original IMP (uiviewcontroller ....)

    NRMAHarvesterConfiguration* config = [[NRMAHarvesterConfiguration alloc] init];
    config.cross_process_id = @"hellworld!";
    id mockInternal = [OCMockObject niceMockForClass:[NRMAHarvestController class]];
    [[[mockInternal stub] andReturn:config]  configuration];;

    IMP tmp = [NRMANSURLConnectionSupport getNRMA_InitWithRequest_Delegate_StartImmediately];
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"google.com"]
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:10.0];

    IMP override = imp_implementationWithBlock([(id)[^(id _self, NSURLRequest* request, id<NSURLConnectionDelegate> delegate,BOOL startImmdeiately){
        XCTAssertTrue([delegate isKindOfClass:[NRMANSURLConnectionDelegateBase class]], @"we should have replaced the proxy object");
        XCTAssertTrue(request.timeoutInterval == 10.0, @"make sure we didn't pervert the data");
        XCTAssertTrue(request.cachePolicy == NSURLRequestUseProtocolCachePolicy, @"make sure we didn't didn't pervert the data");
        XCTAssertTrue([request.URL.path isEqualToString:@"google.com"], @"verify data");
        XCTAssertTrue([[request.allHTTPHeaderFields objectForKey:NEW_RELIC_CROSS_PROCESS_ID_HEADER_KEY] length], @"verify we added a cross process id");

        if ( startImmdeiately) {
            XCTAssertTrue([((NRMANSURLConnectionDelegateBase*)delegate) timer].startTimeMillis != 0, @"assert the timer has been started");
        } else {
            XCTAssertTrue([((NRMANSURLConnectionDelegateBase*)delegate) timer].startTimeMillis == 0, @"assert the timer has not been started");
        }

    }copy]autorelease]);

    [NRMANSURLConnectionSupport set__NRMA__initWithRequest_delegate_startImmediately:override];

    [[NSURLConnection alloc] initWithRequest:request delegate:self];

    [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];

    [NRMANSURLConnectionSupport set__NRMA__initWithRequest_delegate_startImmediately:tmp];

    [mockInternal stopMocking];

    imp_removeBlock(override);
    //we need to verify that tmp is reset to the IMP in NRMANSULRConnectionSupport or else bad things happen.
    assert(tmp == [NRMANSURLConnectionSupport getNRMA_InitWithRequest_Delegate_StartImmediately]);

}

@end
