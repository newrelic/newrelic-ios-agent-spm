//
//  NRMASummaryMeasurementConsumerStressor.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/24/17.
//  Copyright © 2017 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMASummaryMeasurementConsumer.h"
#import "NRMAStressTestHelper.h"
#import "NRMAHTTPTransactionMeasurement.h"
#import "NRMAMethodSummaryMeasurement.h"

@interface NRMASummaryMeasurementConsumer (test)
- (void) consumeMeasurement:(NRMAMeasurement *)measurement;
- (void) consumeHTTPMeasurement:(NRMAHTTPTransactionMeasurement*) measurement;
- (void) consumeMethodMeasurement:(NRMAMethodSummaryMeasurement*)measurement;
@end

@interface NRMASummaryMeasurementConsumerStressor : XCTestCase
@property(atomic) unsigned long long asyncStartedCounter;
@property(atomic) unsigned long long asyncEndedCounter;
@property(strong) dispatch_semaphore_t semaphore;
@property(strong) NRMASummaryMeasurementConsumer* consumer;
@end

@implementation NRMASummaryMeasurementConsumerStressor

- (void)setUp {
    [super setUp];
    self.consumer = [[NRMASummaryMeasurementConsumer alloc] init];
    NSUInteger procCount = [[NSProcessInfo processInfo] processorCount];
    self.semaphore = dispatch_semaphore_create((long)procCount*kNRMASemaphoreMultiplier);
}

- (void)tearDown {
    self.consumer = nil;
    [super tearDown];
}

- (void) testStress {
    int iterations = kNRMAIterations;
    for (int i = 0; i<iterations; i++) {
        @autoreleasepool {
            [self incrementAsyncCounter];
            dispatch_semaphore_wait(self.semaphore,DISPATCH_TIME_FOREVER);
            dispatch_async([NRMAStressTestHelper randomDispatchQueue],^{
               @autoreleasepool {
                   [self randomlyExecute];
                   [self incrementAsyncEndedCounter];
                   dispatch_semaphore_signal(self.semaphore);

               }
            });
        }
    }
    while (CFRunLoopGetCurrent() && self.asyncEndedCounter < self.asyncStartedCounter) {}

}

- (void) randomlyExecute {
    int option = 9;
    switch (rand() % option) {
        case 0:
        case 1:
        case 2:
        case 3: {
            NSDate* date = [NSDate date];
            [self.consumer consumeHTTPMeasurement:[[NRMAHTTPTransactionMeasurement alloc] initWithURL:@"http://asdf.com"
                                                                                           httpMethod:@"POST"
                                                                                              carrier:@"wifi"
                                                                                            startTime:[date timeIntervalSince1970] - 20
                                                                                            totalTime:20
                                                                                           statusCode:200
                                                                                            errorCode:0
                                                                                            bytesSent:100
                                                                                        bytesReceived:100
                                                                                              appData:@""
                                                                                              wanType:@"wifi"
                                                                                           threadInfo:[[NRMAThreadInfo alloc] init]]];
        }
            break;
        case 4:
        case 5:
        case 6:
        case 7: {
            NSDate* date = [NSDate date];
            [self.consumer consumeMethodMeasurement:[[NRMAMethodSummaryMeasurement alloc] initWithName:@"helloWorld"
                                                                                                 scope:@""
                                                                                             startTime:[date timeIntervalSince1970]-20
                                                                                               endtime:[date timeIntervalSince1970]
                                                                                         exclusiveTime:20
                                                                                         traceCategory:NRTraceTypeDatabase]];
        }
            break;
        case 8:
           [self.consumer aggregateAndNormalizeAndRecordValuesWithTotalTime:123 scope:@"jolly/roger"];
            break;
        default:
            break;
    }
}

- (void) incrementAsyncCounter
{
    static NSString* lock = @"mylock";
    @synchronized(lock) {
        self.asyncStartedCounter++;
    }
}
- (void)incrementAsyncEndedCounter
{
    static NSString* lock = @"myLock2";
    @synchronized(lock) {
        self.asyncEndedCounter++;
    }
}

@end
