//
//  NRMACrashDataUploaderTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 7/10/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMACrashDataUploader.h"
#import "NRAgentTestBase.h"
#import "NewRelicAgentInternal.h"
#import "NewRelicInternalUtils.h"

@interface NRMACrashDataUploader ()

- (void) uploadFileAtPath:(NSURL*)path;

- (instancetype) initWithCrashCollectorURL:(NSString*)url
                          applicationToken:(NSString*)token
                     connectionInformation:(NRMAConnectInformation*)connectionInformation
                                    useSSL:(BOOL)useSSL;

- (BOOL) shouldUploadFileWithUniqueIdentifier:(NSString*)path;

- (NSURLRequest*) buildPostFromFilePath:(NSString*)path;

@end
@interface NRMACrashDataUploaderTest : NRMAAgentTestBase
{
    NRMACrashDataUploader* crashUploader;
}
@end

@implementation NRMACrashDataUploaderTest

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testHeaderGeneration {
    NRMACrashDataUploader* uploader = [[NRMACrashDataUploader alloc] initWithCrashCollectorURL:@"google.com"
                                                                              applicationToken:@"token"
                                                                         connectionInformation:[NRMAAgentConfiguration connectionInformation]
                                                                                        useSSL:YES];
    

    NSURLRequest* request = [uploader buildPostFromFilePath:@"helloWorld"];

    XCTAssertTrue(request != nil);

    XCTAssertTrue([request.allHTTPHeaderFields[NEW_RELIC_APP_VERSION_HEADER_KEY] isEqualToString:@"1.0"]);
    XCTAssertTrue([request.allHTTPHeaderFields[X_APP_LICENSE_KEY_REQUEST_HEADER] isEqualToString:@"token"]);
    XCTAssertTrue([request.allHTTPHeaderFields[NEW_RELIC_OS_NAME_HEADER_KEY] isEqualToString:[NewRelicInternalUtils osName]]);
    XCTAssertTrue([request.URL.absoluteString isEqualToString:@"https://google.com/mobile_crash"]);
}
- (void) testBadURL
{
    NRMACrashDataUploader* uploader = [[NRMACrashDataUploader alloc] initWithCrashCollectorURL:nil
                                                                              applicationToken:@"token"
                                                                         connectionInformation:[NRMAAgentConfiguration connectionInformation]
                                                                                        useSSL:YES];
    
    XCTAssertNoThrow([uploader uploadCrashReports], @"this should fail without crashing");

    XCTAssertNoThrow([uploader uploadFileAtPath:nil], @"this should fail without crashing");
}

- (void) testLimitUploads{
    NRMACrashDataUploader* uploader = [[NRMACrashDataUploader alloc] initWithCrashCollectorURL:nil
                                                                              applicationToken:@"token"
                                                                         connectionInformation:[NRMAAgentConfiguration connectionInformation]
                                                                                        useSSL:YES];
    uploader.applicationToken = @"token";

    for(int i = 0; i < kNRMAMaxCrashUploadRetry ;i++){
        XCTAssertTrue([uploader shouldUploadFileWithUniqueIdentifier:@"helloWorld"]);
    }
    XCTAssertFalse([uploader shouldUploadFileWithUniqueIdentifier:@"helloWorld"]);
}

@end
