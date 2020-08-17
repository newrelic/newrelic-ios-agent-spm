//
//  TestHexUploader.m
//  NewRelic
//
//  Created by Bryce Buchanan on 7/24/17.
//  Copyright (c) 2017 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAHexUploader.h"
#import <OCMock/OCMock.h>

@interface NRMAHexUploader ()
- (void) handledErroredRequest:(NSURLRequest*)request;
@end

@interface TestHexUploader : XCTestCase
@property(strong) NRMAHexUploader* hexUploader;
@end

@implementation TestHexUploader

- (void)setUp {
    [super setUp];
    self.hexUploader = [[NRMAHexUploader alloc] initWithHost:@"localhost"];
}

- (void)tearDown {
    [super tearDown];
}

- (void) testNilHost {
    XCTAssertNoThrow([[NRMAHexUploader alloc] initWithHost:nil]);
    self.hexUploader = [[NRMAHexUploader alloc] initWithHost:nil];
    NSString* buf = @"hello world";
    XCTAssertNoThrow([self.hexUploader sendData:[NSData dataWithBytes:buf.UTF8String
                                              length:buf.length]]);
}

- (void) testNilData {

    XCTAssertNoThrow([self.hexUploader sendData:nil]);
}

- (void) testHandledNetworkError {
    id mockUploader = [OCMockObject partialMockForObject:self.hexUploader];
    [[mockUploader expect] handledErroredRequest:OCMOCK_ANY];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:nil
                                                              statusCode:400
                                                             HTTPVersion:@"1.1"
                                                            headerFields:nil];

    [mockUploader URLSession:nil
                    dataTask:nil
          didReceiveResponse:response
           completionHandler:^(NSURLSessionResponseDisposition d){}];
#pragma clang diagnostic pop

    XCTAssertNoThrow([mockUploader verify]);

    [mockUploader stopMocking];
}
- (void) testNoRetryOnSuccess {
    id mockUploader = [OCMockObject partialMockForObject:self.hexUploader];
    [[mockUploader expect] handledErroredRequest:OCMOCK_ANY];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

    NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:nil
                                                              statusCode:201
                                                             HTTPVersion:@"1.1"
                                                            headerFields:nil];

    [mockUploader URLSession:nil
                    dataTask:nil
          didReceiveResponse:response
           completionHandler:^(NSURLSessionResponseDisposition d){}];
#pragma clang diagnostic pop

    XCTAssertThrows([mockUploader verify]);

    [mockUploader stopMocking];
}

- (void) testNoRetryOnCancel {
    id mockUploader = [OCMockObject partialMockForObject:self.hexUploader];
    [[mockUploader expect] handledErroredRequest:OCMOCK_ANY];

    NSError* error = [NSError errorWithDomain:(NSString*)kCFErrorDomainCFNetwork
                                         code:kCFURLErrorCancelled
                                     userInfo:nil];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [mockUploader URLSession:nil task:nil didCompleteWithError:error];
#pragma clang diagnostic pop

    XCTAssertThrows([mockUploader verify]);

    [mockUploader stopMocking];

}

- (void) testRetryOnFailure {
    id mockUploader = [OCMockObject partialMockForObject:self.hexUploader];
    [[mockUploader expect] handledErroredRequest:OCMOCK_ANY];

    NSError* error = [NSError errorWithDomain:(NSString*)kCFErrorDomainCFNetwork
                                         code:kCFURLErrorDNSLookupFailed
                                     userInfo:nil];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [mockUploader URLSession:nil task:nil didCompleteWithError:error];
#pragma clang diagnostic pop

    XCTAssertNoThrow([mockUploader verify]);

    [mockUploader stopMocking];

}

@end
