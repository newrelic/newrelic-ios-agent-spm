//
//  APINetworkNoticeTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 11/7/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMeasurementConsumerHelper.h"
#import "NRMAMeasurements.h"
#import "NRMAHTTPTransactionMeasurement.h"
#import "NRMATaskQueue.h"
#import "NRMANetworkFacade.h"
#import "NewRelicAgentInternal.h"
@interface NRMATaskQueue ()
+ (NRMATaskQueue*) taskQueue;
- (void) dequeue;
@end

@interface APINetworkNoticeTest : XCTestCase
{
    NRMAMeasurementConsumerHelper* helper;
}
@end

@implementation APINetworkNoticeTest

- (void)setUp
{
    [super setUp];
    helper = [[NRMAMeasurementConsumerHelper alloc] initWithType:NRMAMT_HTTPTransaction];
    [NRMAMeasurements initializeMeasurements];
    [NRMAMeasurements addMeasurementConsumer:helper];
}

- (void)tearDown
{
    [NRMAMeasurements removeMeasurementConsumer:helper];
    [NRMAMeasurements shutdown];
    [super tearDown];
}

- (void) testNoticeNetworkRequest
{
    NRTimer* timer = [[NRTimer alloc] init];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"google.com"]];
    NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                              statusCode:200
                                                             HTTPVersion:nil
                                                            headerFields:nil];
    [NRMANetworkFacade noticeNetworkRequest:request
                                   response:response
                                  withTimer:timer
                                  bytesSent:0
                              bytesReceived:0
                               responseData:nil
                                     params:nil];

    while(CFRunLoopGetCurrent() && !helper.result){
    };

    NRMAHTTPTransactionMeasurement* result = (NRMAHTTPTransactionMeasurement*)helper.result;
    XCTAssertEqualObjects(result.url, @"google.com", @"result url matches recorded url");
    XCTAssertEqual(result.startTime, timer.startTimeMillis, @"");
    XCTAssertEqual((long long)result.endTime,  (long long)timer.endTimeMillis,@"");
    XCTAssertEqual(result.statusCode, 200, @"");
}

- (void) testNoticeNilValues
{

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"google.com"]];

    NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                              statusCode:200
                                                             HTTPVersion:nil
                                                            headerFields:nil];
    XCTAssertNoThrow([NRMANetworkFacade noticeNetworkRequest:request
                                                    response:response
                                                   withTimer:nil
                                                   bytesSent:0
                                               bytesReceived:0
                                                responseData:nil
                                                      params:nil], @"crashed because of nil values");
}

@end
