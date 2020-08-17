//
//  NRMAMeasurementsTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/4/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMeasurementsTest.h"
#import "NRMAMeasurements.h"
#import "NRMAMeasurementEngine.h"
#import "NRTimer.h"
#import "NRMANamedValueProducer.h"
#import <OCMock/OCMock.h>
#import "NRMANamedValueMeasurement.h"
#import "NRMAActivityTraceMeasurementProducer.h"
#import "NRMAHarvestController.h"
#import "NRMAMethodSummaryMeasurement.h"
#import "NRMAHTTPTransactionMeasurementProducer.h"
#import "NRMAHarvestableHTTPErrors.h"
#import "NRMATaskQueue.h"
#import "NRMAHTTPTransactionMeasurement.h"

@interface NRMAMeasurements ()
- (NRMAMeasurementEngine *)engine;

+ (NRMAActivityTraceMeasurementProducer *)activityTraceMeasurementProducer;

+ (NRMAHTTPTransactionMeasurementProducer *)httpTransactionMeasurementProducer;

+ (void) recordHTTPTransactionWithURL:(NSString*)url
                           httpMethod:(NSString*)httpMethod
                            startTime:(double)startTime
                            totalTime:(double)totalTime
                            bytesSent:(long long)bytesSent
                        bytesReceived:(long long)bytesReceived
                           statusCode:(int)statusCode
                          failureCode:(int)failureCode
                              appData:(NSString*)appdata
                              wanType:(NSString*)wanType
                           threadInfo:(NRMAThreadInfo*)threadInfo;

+ (void)recordMetric:(NRMAMetric *)metric;

+ (void)recordActivityTrace:(NRMAActivityTrace *)trace;

+ (void)recordSummaryMeasurements:(NRMATrace *)trace;
@end

@interface NRMAHarvestableHTTPErrors (test)
- (NSMutableDictionary *)dictionary;
@end

@implementation NRMAHarvestableHTTPErrors (test)
- (NSMutableDictionary *)dictionary {
    return httpErrors;
}
@end

@implementation NRMAMeasurementsTest
- (void)setUp {
    [super setUp];
    [NRMAMeasurements initializeMeasurements];

}

- (void)tearDown {
    [NRMAMeasurements shutdown];
    [super tearDown];
}

- (void)testInitialization {

}

- (void) testRecordNetworkMetric {
    NSMutableArray* array = [NSMutableArray new];

    NRMAHTTPTransactionMeasurement* t1 = [[NRMAHTTPTransactionMeasurement alloc] initWithURL:@"google.com"
                                                                                  httpMethod:@"get"
                                                                                     carrier:@"WIFI"
                                                                                   startTime:0
                                                                                   totalTime:1000
                                                                                  statusCode:200
                                                                                   errorCode:0
                                                                                   bytesSent:0
                                                                               bytesReceived:0
                                                                                     appData:@""
                                                                                     wanType:@"WIFI"
                                                                                  threadInfo:[NRMAThreadInfo new]];
    NRMAHTTPTransactionMeasurement* t2 = [[NRMAHTTPTransactionMeasurement alloc] initWithURL:@"google.com"
                                                                                  httpMethod:@"get"
                                                                                     carrier:@"WIFI"
                                                                                   startTime:0
                                                                                   totalTime:1000
                                                                                  statusCode:200
                                                                                   errorCode:0
                                                                                   bytesSent:0
                                                                               bytesReceived:0
                                                                                     appData:@""
                                                                                     wanType:@"WIFI"
                                                                                  threadInfo:[NRMAThreadInfo new]];
    NRMAHTTPTransactionMeasurement* t3 = [[NRMAHTTPTransactionMeasurement alloc] initWithURL:@"google.com"
                                                                                  httpMethod:@"get"
                                                                                     carrier:@"WIFI"
                                                                                   startTime:0
                                                                                   totalTime:1000
                                                                                  statusCode:200
                                                                                   errorCode:0
                                                                                   bytesSent:0
                                                                               bytesReceived:0
                                                                                     appData:@""
                                                                                     wanType:@"WIFI"
                                                                                  threadInfo:[NRMAThreadInfo new]];

    //this should not get captured.
    NRMANamedValueMeasurement* t4 = [[NRMANamedValueMeasurement alloc] initWithName:@"blah" value:@1];
    t4.startTime = 0;
    t4.endTime = 999;

    [array addObject:t1];
    [array addObject:t2];
    [array addObject:t3];
    [array addObject:t4];

    __block NSString* interactionName = @"test";

    id mockQueue = [OCMockObject niceMockForClass:[NRMATaskQueue class]];
    __block int count = 0;
    __block BOOL foundCount = NO;
    __block BOOL foundTime = NO;
    [[[[mockQueue stub] classMethod] andDo:^(NSInvocation *invocation) {
        count++;
        __autoreleasing id metric;

        [invocation getArgument:&metric atIndex:2];
        XCTAssertTrue([metric isKindOfClass:[NRMAMetric class]], @"captured wrong type of object");

        if ([((NRMAMetric*)metric).name isEqualToString:[NSString stringWithFormat:@"Mobile/Activity/Network/%@/Count",interactionName]]) {
            XCTAssertEqual(((NRMAMetric*)metric).value.integerValue, 3,@"incorrect count metric");
            foundCount = YES;
        } else if ([((NRMAMetric*)metric).name isEqualToString:[NSString stringWithFormat:@"Mobile/Activity/Network/%@/Time",interactionName]]) {
            XCTAssertEqual(((NRMAMetric*)metric).value.integerValue, 3,@"incorrect time metric");
            foundTime = YES;
        } else {
            XCTFail(@"incorrect metric name.");
        }
        
    }] queue:OCMOCK_ANY];

    [NRMAMeasurements recordNetworkMetricsFromMetrics:array forActivity:interactionName];

    while (CFRunLoopGetCurrent() && !foundTime && !foundCount) {}
    XCTAssertEqual(count, 2, @"failed metric count");
    [mockQueue stopMocking];

}

- (void) testRecordNetworkBadData {
    NSMutableArray* array = [NSMutableArray new];

    //this isn't a measurement.
    NRMAHTTPTransaction* t1 = [[NRMAHTTPTransaction alloc] initWithURL:@"google.com"
                                                            httpMethod:@"GET"
                                                             startTime:0
                                                             totalTime:1000
                                                             bytesSent:100
                                                         bytesReceived:0
                                                            statusCode:200
                                                           failureCode:0
                                                               appData:@""
                                                               wanType:@"WIFI"
                                                            threadInfo:[NRMAThreadInfo new]];

    [array addObject:t1];

    id mockQueue = [OCMockObject niceMockForClass:[NRMATaskQueue class]];

    [[[mockQueue expect] classMethod] queue:OCMOCK_ANY];

    XCTAssertNoThrow([NRMAMeasurements recordNetworkMetricsFromMetrics:array forActivity:@"blah"], @"should handle bad data gracefully.");

    XCTAssertNoThrow([mockQueue verify], @"mockQueue shouldn't have been called");

    [mockQueue stopMocking];
}


- (void)testRecordNamedValueException {

    NSString *name = @"aName";
    NSNumber *myvalue = @12;
    NSString *scope = @"asdf";

    id namedValueMeasurement = [OCMockObject niceMockForClass:[NRMANamedValueMeasurement class]];
    id measurementProducer = [OCMockObject niceMockForClass:[NRMANamedValueProducer class]];
    [[[measurementProducer stub] andDo:^(NSInvocation *invocation) {
        NRMANamedValueMeasurement *argument = nil;
        [invocation getArgument:&argument atIndex:2];
        if (argument.name == name && argument.value == myvalue && argument.scope == scope) {
            XCTFail(@"unexpected metric was produced after an exception occured.");
        }
    }] produceMeasurement:OCMOCK_ANY];

    [[[namedValueMeasurement stub] andDo:^(NSInvocation *invocation) {
        [namedValueMeasurement stopMocking];
        @throw [NSException exceptionWithName:@"meh" reason:@"meh" userInfo:nil];
    }] alloc];

    @try {

        [NRMAMeasurements recordMetric:[[NRMAMetric alloc] initWithName:name value:myvalue scope:scope produceUnscoped:YES]];

    } @catch (NSException *exception) {
        XCTAssertTrue([exception.name isEqualToString:kNRMAMetricException], @"assert the kind of exception we see is a metric exception.");
    }

    [measurementProducer stopMocking];
}

- (void)testRecordActivityTraceException {

    id mockActivityTraceProducer = [OCMockObject partialMockForObject:[NRMAMeasurements activityTraceMeasurementProducer]];
    [[[mockActivityTraceProducer stub] andDo:^(NSInvocation *invocation) {

        @throw [NSException exceptionWithName:@"asdf" reason:@"asdf" userInfo:nil];
    }] produceMeasurementWithTrace:OCMOCK_ANY];

    XCTAssertNoThrow([NRMAMeasurements recordActivityTrace:nil], @"");

    [mockActivityTraceProducer stopMocking];
}

- (void)testRecordSummaryMeasurementException {
    id mockSummaryMeasurement = [OCMockObject mockForClass:[NRMAMethodSummaryMeasurement class]];

    [[[mockSummaryMeasurement stub] andDo:^(NSInvocation *invok) {
        @throw [NSException exceptionWithName:@"asdf" reason:@"asf" userInfo:nil];
    }] alloc];

    XCTAssertNoThrow([NRMAMeasurements recordSummaryMeasurements:nil], @"assert no throw");

    [mockSummaryMeasurement stopMocking];

}

- (void)testRecordHTTPException
{
    id httpMock = [OCMockObject partialMockForObject:[NRMAMeasurements httpTransactionMeasurementProducer]];
    [[[httpMock stub] andDo:^(NSInvocation* invocation) {
        @throw [NSException exceptionWithName:@"asdf"
                                       reason:@"asdf"
                                     userInfo:nil];
    }] produceHttpTransaction:OCMOCK_ANY
                   httpMethod:nil
                      carrier:OCMOCK_ANY
                    startTime:0
                    totalTime:0
                   statusCode:0
                    errorCode:0
                    bytesSent:0
                bytesReceived:0
                      appData:nil
                      wanType:OCMOCK_ANY
                   threadInfo:OCMOCK_ANY];


    XCTAssertNoThrow([NRMAMeasurements recordHTTPTransactionWithURL:nil
                                                         httpMethod:nil
                                                          startTime:0
                                                          totalTime:0
                                                          bytesSent:0
                                                      bytesReceived:0
                                                         statusCode:0
                                                        failureCode:0
                                                            appData:nil
                                                            wanType:nil
                                                         threadInfo:nil],
                     @"assert exception doesn't bubble up");

    [httpMock stopMocking];
}
@end
