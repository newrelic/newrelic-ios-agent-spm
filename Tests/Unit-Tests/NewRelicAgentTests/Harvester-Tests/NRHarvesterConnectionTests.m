//
//  NRMAHarvesterConnectionTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/28/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRHarvesterConnectionTests.h"
#import "NewRelicInternalUtils.h"
#import "NRTestConstants.h"
#import "NewRelicAgentInternal.h"
#import <OCMock/OCMock.h>
@implementation NRMAHarvesterConnectionTests

- (void) setUp
{
    [super setUp];
    connection = [[NRMAHarvesterConnection alloc] init];
    connection.applicationToken = @"app token";
    connection.connectionInformation = [NRMAAgentConfiguration connectionInformation];
}

- (void) testCreatePost
{
    NSString* url = @"http://mobile-collector.newrelic.com/foo";
    NSURLRequest* post = [connection createPostWithURI:url message:@"hello world"];

    XCTAssertTrue([post.allHTTPHeaderFields[NEW_RELIC_OS_NAME_HEADER_KEY] isEqualToString:[NewRelicInternalUtils osName]]);
    XCTAssertTrue([post.allHTTPHeaderFields[NEW_RELIC_APP_VERSION_HEADER_KEY] isEqualToString:@"1.0"]);
    XCTAssertTrue([post.allHTTPHeaderFields[X_APP_LICENSE_KEY_REQUEST_HEADER] isEqualToString:@"app token"]);
    XCTAssertNotNil(post, @"expected creation of Post");
    XCTAssertTrue([[post HTTPMethod] isEqualToString:@"POST"], @"method type should be post.");
    XCTAssertTrue([[post URL].absoluteString isEqualToString:url], @"urls should match");
}

- (void) testCreateConnectPost
{
    connection.collectorHost = @"mobile-collector.newrelic.com";
    NSString* url = @"http://mobile-collector.newrelic.com/mobile/v4/connect";
    NSURLRequest* request = [connection createConnectPost:@"hello world"];
    XCTAssertNotNil(request, @"");
    XCTAssertTrue([request.HTTPMethod isEqualToString:@"POST"], @"");
    XCTAssertTrue([request.URL.absoluteString isEqualToString:url], @"should match");
    
    connection.useSSL = YES;
    request = [connection createConnectPost:@"hello2"];
    XCTAssertNotNil(request, @"");
    XCTAssertTrue([[request.URL.absoluteString substringWithRange:NSMakeRange(0, 5)] rangeOfString:@"https"].location != NSNotFound,@"");
}
- (void) testSend {
    __block NSURLResponse* bresponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://mobile-collector.newrelic.com"] statusCode:404 HTTPVersion:@"1.1" headerFields:nil];
    id mockNSURLSession = [OCMockObject mockForClass:NSURLSession.class];
    [[[mockNSURLSession stub] classMethod] andReturn:mockNSURLSession];
    
    connection.harvestSession = mockNSURLSession;
    
    id mockUploadTask = [OCMockObject mockForClass:NSURLSessionUploadTask.class];
    
    
    __block void (^completionHandler)(NSData*, NSURLResponse*, NSError*);
    
    [[[[mockNSURLSession stub] andReturn:mockUploadTask] andDo:^(NSInvocation * invoke) {
        [invoke getArgument:&completionHandler atIndex:4];
    }] uploadTaskWithRequest:OCMOCK_ANY fromData:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    
    [[[mockUploadTask stub] andDo:^(NSInvocation *invoke) {
        completionHandler(nil, bresponse, nil);
    }] resume];
    
    connection.serverTimestamp = 1234;
     connection.collectorHost = @"mobile-collector.newrelic.com";
     
     NSURLRequest* request = [connection createConnectPost:@"unit tests"];
     XCTAssertNotNil(request, @"");
     
     NRMAHarvestResponse* response = [connection send:request];
     XCTAssertNotNil(response, @"");
     XCTAssertEqual(404, response.statusCode, @"we should be not found!");
     XCTAssertTrue([response.responseBody isEqualToString:@""], @"");
     
     XCTAssertTrue([response isError], @"");
     XCTAssertTrue(response.statusCode == NOT_FOUND, @"");
     
     [mockUploadTask stopMocking];
     [mockNSURLSession stopMocking];
}
//
//- (void) testSend
//{
//    @autoreleasepool {
//
//    __block NSURLResponse* bresponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://mobile-collector.newrelic.com"] statusCode:404 HTTPVersion:@"1.1" headerFields:nil];
//    id mockConnection = [OCMockObject mockForClass:NSURLConnection.class];
//
//    [[[[mockConnection stub] classMethod] andDo:^(NSInvocation* invoke){
//        @autoreleasepool {
//
//        NSURLResponse* __autoreleasing * response_ptr;
//
//        [invoke getArgument:&response_ptr atIndex:3];
//
//        *response_ptr = bresponse;
//        }
//
//    }]   sendSynchronousRequest:OCMOCK_ANY
//              returningResponse:[OCMArg anyObjectRef]
//                          error:[OCMArg anyObjectRef]];
//
//    connection.serverTimestamp = 1234;
//    connection.collectorHost = @"mobile-collector.newrelic.com";
//
//    NSURLRequest* request = [connection createConnectPost:@"unit tests"];
//    XCTAssertNotNil(request, @"");
//
//    NRMAHarvestResponse* response = [connection send:request];
//    XCTAssertNotNil(response, @"");
//    XCTAssertEqual(404, response.statusCode, @"we should be not found!");
//    XCTAssertTrue([response.responseBody isEqualToString:@""], @"");
//
//    XCTAssertTrue([response isError], @"");
//    XCTAssertTrue(response.statusCode == NOT_FOUND, @"");
//
//    [mockConnection stopMocking];
//    }
//}


- (NRMAConnectInformation*) testSendConnect
{
    connection.serverTimestamp =1234;
    connection.connectionInformation = [self createConnectionInformation];
    
    connection.collectorHost = @"mobile-collector.newrelic.com";
    
    NRMAHarvestResponse* response = [connection sendConnect];
    XCTAssertNotNil(response, @"");
    XCTAssertEqual(FORBIDDEN,response.statusCode, @"");
    XCTAssertTrue([response.responseBody isEqualToString:@""],@"");
}

- (void) testSendData
{
    connection.serverTimestamp = 1234;
    connection.collectorHost = @"mobile-collector.newrelic.com";
    
    NRMAHarvestResponse* response = [connection sendData:[self createConnectionInformation]];
    XCTAssertNotNil(response, @"");
    XCTAssertEqual(FORBIDDEN, response.statusCode, @"");
    //API changed, and is now returning a response. Though it's not imparative this repsonse is empty.
    //nothing in the harvester depends on it, so this test is not needed.
//    XCTAssertTrue([response.responseBody isEqualToString:@""], @"");
}


- (void) testSendDisabledAppToken
{
    
    connection.applicationToken = @"AA25e94fba740f136033f66f92099a8eab3ea4bd9b";
    connection.collectorHost= @"staging-mobile-collector.newrelic.com";
    
    NSURLRequest* request = [connection createConnectPost:@"Unit Test"];
    XCTAssertNotNil(request, @"");
    
    NRMAHarvestResponse* response = [connection send:request];
    XCTAssertNotNil(response, @"");
    
    XCTAssertEqual(FORBIDDEN, response.statusCode, @"");
    XCTAssertTrue([@"DISABLE_NEW_RELIC" isEqualToString:response.responseBody], @"");
}
- (void) testSendEnabledAppToken
{
    connection.connectionInformation = [self createConnectionInformation];
    connection.collectorHost = @"staging-mobile-collector.newrelic.com";
    connection.applicationToken = @"AAa2d4baa1094bf9049bb22895935e46f85c45c211";
    
    NRMAHarvestResponse* response= [connection sendConnect];
    XCTAssertNotNil(response, @"");
    
    XCTAssertEqual(response.statusCode,200, @"");
    XCTAssertTrue([response.responseBody rangeOfString:@"data_token"].location != NSNotFound,@"");
    	
}

- (void) testCollectorCompression
{
    //TODO: write test for gzip of posts > 512 bytes.
    NSMutableString* message = [[NSMutableString alloc]initWithCapacity:513];
    for (int i = 0; i < 513; i++)
        [message appendFormat:@"a"];
    NSURLRequest* generatedRequest = [connection createPostWithURI:@"helloworld" message:message];
    
    XCTAssertEqualObjects([generatedRequest.allHTTPHeaderFields objectForKey:@"Content-Encoding"], @"deflate", @"");
}

- (NRMAConnectInformation*) createConnectionInformation
{
    NSString* appName = @"test";
    NSString* appversion = @"1.0";
    NSString* packageId = @"com.test";
    NRMAApplicationInformation* appinfo = [[NRMAApplicationInformation alloc] initWithAppName:appName
                                                                               appVersion:appversion
                                                                                 bundleId:packageId];
    NRMADeviceInformation* devInfo = [[NRMADeviceInformation alloc] init];
    devInfo.osName = [NewRelicInternalUtils osName];
    devInfo.osVersion = [NewRelicInternalUtils osVersion];
    devInfo.manufacturer = @"Apple Inc.";
    devInfo.model = [NewRelicInternalUtils deviceModel];
    devInfo.agentName = [NewRelicInternalUtils agentName];
    devInfo.agentVersion = @"2.123";
    devInfo.deviceId =@"389C9738-A761-44DE-8A66-1668CFD67DA1";
    
    NRMAConnectInformation* connectionInformation = [[NRMAConnectInformation alloc] init];
    
    connectionInformation.applicationInformation = appinfo;
    connectionInformation.deviceInformation = devInfo;
    return connectionInformation;
}
@end
