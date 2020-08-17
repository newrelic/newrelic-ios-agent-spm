//
//  NSURLSessionOverrideTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 3/31/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAURLSessionOverride.h"
#import <objc/runtime.h>
#import <dlfcn.h>
#import "NRMAURLSessionTaskDelegate.h"
@interface NSURLSessionOverrideTest : XCTestCase <NSURLSessionDelegate>
- (BOOL) verifyDeinstrumented;
@end

@implementation NSURLSessionOverrideTest

- (void)setUp
{
    [super setUp];
    [NRMAURLSessionOverride beginInstrumentation];
}

- (void)tearDown
{
    [NRMAURLSessionOverride deinstrument];
    XCTAssertTrue([self verifyDeinstrumented], @"Failed to properly deinstrument");
    [super tearDown];
}

- (void) testVerifyInstrumented
{
    Class clazz = [NSURLSession class];
    Dl_info info;

    IMP methodImplementation = class_getMethodImplementation(clazz, @selector(dataTaskWithRequest:));
    dladdr(methodImplementation, &info);
    XCTAssertTrue(methodImplementation == (IMP)NRMAOverride__dataTaskWithRequest, @"%s doesn't match NRMAOverride",info.dli_sname);

    methodImplementation = class_getMethodImplementation(clazz, @selector(dataTaskWithURL:));
    dladdr(methodImplementation, &info);
    XCTAssertTrue(methodImplementation == (IMP)NRMAOverride__dataTaskWithURL,@"%s doesn't match NRMAOverride",info.dli_sname);

    methodImplementation = class_getMethodImplementation(clazz, @selector(dataTaskWithRequest:completionHandler:));
    dladdr(methodImplementation, &info);
    XCTAssertTrue(methodImplementation == (IMP)NRMAOverride__dataTaskWithRequest_completionHandler,@"%s doesn't match NRMAOverride",info.dli_sname);

    methodImplementation = class_getMethodImplementation(clazz, @selector(uploadTaskWithStreamedRequest:));
    dladdr(methodImplementation, &info);
    XCTAssertTrue(methodImplementation == (IMP)NRMAOverride__uploadTaskWithStreamedRequest,@"%s doesn't match NRMAOverride",info.dli_sname);

    methodImplementation = class_getMethodImplementation(clazz, @selector(uploadTaskWithRequest:fromFile:completionHandler:));
    dladdr(methodImplementation, &info);
    XCTAssertTrue(methodImplementation == (IMP)NRMAOverride__uploadTaskWithRequest_fromFile_completionHandler,@"%s doesn't match NRMAOverride",info.dli_sname);

    methodImplementation = class_getMethodImplementation(clazz, @selector(uploadTaskWithRequest:fromFile:));
    dladdr(methodImplementation, &info);
    XCTAssertTrue(methodImplementation == (IMP)NRMAOverride__uploadTaskWithRequest_fromFile,@"%s doesn't match NRMAOverride",info.dli_sname);

    methodImplementation = class_getMethodImplementation(clazz, @selector(uploadTaskWithRequest:fromData:completionHandler:));
    dladdr(methodImplementation, &info);
    XCTAssertTrue(methodImplementation == (IMP)NRMAOverride__uploadTaskWithRequest_fromData_completionHandler,@"%s doesn't match NRMAOverride",info.dli_sname);

    methodImplementation = class_getMethodImplementation(clazz, @selector(uploadTaskWithRequest:fromData:));
    dladdr(methodImplementation, &info);
    XCTAssertTrue(methodImplementation == (IMP)NRMAOverride__uploadTaskWithRequest_fromData,@"%s doesn't match NRMAOverride",info.dli_sname);
}
- (BOOL) verifyDeinstrumented
{
    Class clazz = [NSURLSession class];
    if(class_getMethodImplementation(clazz, @selector(dataTaskWithRequest:))== (IMP)NRMAOverride__dataTaskWithURL){
        return NO;
    }
    if (class_getMethodImplementation(clazz, @selector(dataTaskWithURL:)) == (IMP)NRMAOverride__dataTaskWithURL){
        return NO;
    }
    if (class_getMethodImplementation(clazz, @selector(dataTaskWithRequest:completionHandler:)) == (IMP)NRMAOverride__dataTaskWithRequest_completionHandler){
        return NO;
    }
    if (class_getMethodImplementation(clazz, @selector(uploadTaskWithStreamedRequest:)) == (IMP)NRMAOverride__uploadTaskWithStreamedRequest){
        return NO;
    }
    if (class_getMethodImplementation(clazz, @selector(uploadTaskWithRequest:fromFile:completionHandler:))==(IMP)NRMAOverride__uploadTaskWithRequest_fromFile_completionHandler) {
        return NO;
    }
    if (class_getMethodImplementation(clazz, @selector(uploadTaskWithRequest:fromFile:)) == (IMP)NRMAOverride__uploadTaskWithRequest_fromFile) {
        return NO;
    }
    if (class_getMethodImplementation(clazz, @selector(uploadTaskWithRequest:fromData:completionHandler:))==(IMP)NRMAOverride__uploadTaskWithRequest_fromData_completionHandler){
        return NO;
    }
    if (class_getMethodImplementation(clazz, @selector(uploadTaskWithRequest:fromData:)) == (IMP)NRMAOverride__uploadTaskWithRequest_fromData){
        return NO;
    }

    return YES;
}

- (void) testNSURLSessionDelegateNil
{
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* mySession = [NSURLSession sessionWithConfiguration:config
                                                            delegate:nil
                                                       delegateQueue:[NSOperationQueue mainQueue]];

    XCTAssertNil(mySession.delegate,@"the session delegate was not nil! set to %@",mySession.delegate);
}

- (void) testNSURLSessionDelegateOverride
{
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* mySession = [NSURLSession sessionWithConfiguration:config
                                                            delegate:self
                                                       delegateQueue:[NSOperationQueue mainQueue]];

     XCTAssertTrue([mySession.delegate isKindOfClass:[NRMAURLSessionTaskDelegate class]],@"the session delegate was not NR override class! set to %@",[mySession.delegate class]);
}
@end
