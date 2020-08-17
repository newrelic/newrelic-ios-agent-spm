//
//  NRMAMeasurementsStressor.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/12/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAMeasurements.h"
#import "NRMAStressTestHelper.h"
#import "NRMAActivityTrace.h"


@interface NRMAMeasurementsStressor : XCTestCase
@property(atomic) unsigned long long asyncStartedCounter;
@property(atomic) unsigned long long asyncEndedCounter;
@property(strong) dispatch_semaphore_t semaphore;
@end

@interface NRMAMeasurements (private) //methods only used by NRMATaskQueue

+ (void)recordActivityTrace:(NRMAActivityTrace *)activityTrace;

+ (void)recordSummaryMeasurements:(NRMATrace *)trace;

+ (void)recordHTTPError:(NRMAHTTPError *)error;

+ (void)recordMetric:(NRMAMetric *)metric;

+ (void)recordHTTPTransaction:(NRMAHTTPTransaction *)transaction;
@end

@implementation NRMAMeasurementsStressor

- (void)setUp
{
    [super setUp];
    self.asyncStartedCounter = 0;
    [NRMAMeasurements initializeMeasurements];
    NSUInteger procCount = [[NSProcessInfo processInfo] processorCount];
    self.semaphore = dispatch_semaphore_create(procCount * kNRMASemaphoreMultiplier);
}

- (void)tearDown
{
    [NRMAMeasurements shutdown];
    [super tearDown];
}

- (void)incrementAsyncCounter
{
    static NSString *lock = @"mylock";
    @synchronized (lock) {
        self.asyncStartedCounter++;
    }
}

- (void)incrementAsyncEndedCounter
{
    static NSString *lock = @"myLock2";
    @synchronized (lock) {
        self.asyncEndedCounter++;
    }
}

- (void)testStress
{
    XCTAssertNoThrow([self stress],
                     @"Failed stress test");
}

- (void)stress
{
    int interactions = kNRMAIterations;
    for (int i = 0; i < interactions; i++) {
        @autoreleasepool {
            [self incrementAsyncCounter];
            //These semaphores prevent the dispatch_async calls from blowing out the stack
            //they would otherwise get queued faster than they could be execute
            //thus creating a huge growth in heap size.
            dispatch_semaphore_wait(self.semaphore,
                                    DISPATCH_TIME_FOREVER);
            dispatch_async([NRMAStressTestHelper randomDispatchQueue],
                           ^{
                               @autoreleasepool {
                                   [self randomlyExecute];
                                   [self incrementAsyncEndedCounter];
                                   dispatch_semaphore_signal(self.semaphore);
                               }
                           });

            [self incrementAsyncCounter];
            //These semaphores prevent the dispatch_async calls from blowing out the stack
            //they would otherwise get queued faster than they could be execute
            //thus creating a huge growth in heap size.
            dispatch_semaphore_wait(self.semaphore,
                                    DISPATCH_TIME_FOREVER);
            dispatch_async([NRMAStressTestHelper randomDispatchQueue],
                           ^{
                               switch (rand() % 2) {
                                   case 0:
                                       [NRMAMeasurements initializeMeasurements];
                                       break;
                                   case 1:
                                       [NRMAMeasurements shutdown];
                                       break;
                                   default:
                                       break;
                               }
                               [self incrementAsyncEndedCounter];
                               dispatch_semaphore_signal(self.semaphore);
                           });
        }
    }

    while (CFRunLoopGetCurrent() && self.asyncEndedCounter < self.asyncStartedCounter) {}
}

- (void)randomlyExecute
{
    @autoreleasepool {

        int options = 11;
        switch (rand() % options) {
            case 0:
                [NRMAMeasurements recordSessionStartMetric];
                break;
            case 1:
                [NRMAMeasurements processCurrentSummaryMetricsWithTotalTime:10
                                                               activityName:@"meh"];
                break;
            case 2:
                [NRMAMeasurements recordActivityTrace:[[NRMAActivityTrace alloc] initWithRootTrace:[[NRMATrace alloc] initWithName:@"asdf"
                                                                                                                      traceMachine:nil]]];
                break;
            case 3:
                [NRMAMeasurements recordSummaryMeasurements:[[NRMATrace alloc] initWithName:@"ffdsf"
                                                                               traceMachine:nil]];
                break;
            case 4:
                [NRMAMeasurements recordBackgroundScopedMetricNamed:@"asdfasdf"
                                                              value:@1];
                break;
            case 5:
                [NRMAMeasurements recordAndScopeMetricNamed:@"ffjfsjdskfj"
                                                      value:@12];
                break;
            case 6:
                [NRMAMeasurements recordMetric:[[NRMAMetric alloc] initWithName:@"fffdsdf"
                                                                          value:@33
                                                                          scope:@"asdfasdf"]];
                break;
            case 7:
                [NRMAMeasurements recordAndScopeMetricNamed:@"ghhfdfgrte"
                                                      value:@99];
                break;
            case 8:
                [NRMAMeasurements recordHTTPTransaction:[[NRMAHTTPTransaction alloc] initWithURL:@"asdfasdf"
                                                                                      httpMethod:nil
                                                                                       startTime:10000
                                                                                       totalTime:10000
                                                                                       bytesSent:1
                                                                                   bytesReceived:1
                                                                                      statusCode:200
                                                                                     failureCode:0
                                                                                         appData:@"abcd"
                                                                                         wanType:nil
                                                                                      threadInfo:[NRMAThreadInfo new]]];
                break;
            case 9:
                [NRMAMeasurements process];
                break;
            case 10:
                [NRMAMeasurements recordHTTPError:[[NRMAHTTPError alloc] initWithURL:@"ffefef"
                                                                          httpMethod:nil
                                                                         timeOfError:123123123
                                                                          statusCode:1234
                                                                        responseBody:@""
                                                                          parameters:nil
                                                                             wanType:nil
                                                                        appDataToken:nil
                                                                          threadInfo:[NRMAThreadInfo new]]];
                break;
            default:
                break;
        }
    }
}

@end
