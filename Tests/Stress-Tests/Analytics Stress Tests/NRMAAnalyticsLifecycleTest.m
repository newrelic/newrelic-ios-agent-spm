//
//  NRMAAnalyticsLifecycleTest.m
//  NewRelic
//
//  Created by Bryce Buchanan on 5/8/15.
//  Copyright (c) 2015 New Relic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NRMAAnalytics.h"
#import "NRMAStressTestHelper.h"
#import <XCTest/XCTest.h>

@interface NRMAAnalyticsLifecycleTest : XCTestCase
@property(atomic,strong) NRMAAnalytics* analytics;
@property(atomic) unsigned long long asyncStartedCounter;
@property(atomic) unsigned long long asyncEndedCounter;
@property(strong) dispatch_semaphore_t semaphore;
@end

@implementation NRMAAnalyticsLifecycleTest

- (void)setUp {
    [super setUp];
    self.analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:0];
    NSUInteger procCount = [[NSProcessInfo processInfo] processorCount];
    self.semaphore = dispatch_semaphore_create(procCount * kNRMASemaphoreMultiplier);
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

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testStress {
    XCTAssertNoThrow([self stress], @"");
}


- (void) stress {
    int iterations = kNRMAIterations;
    for (int i = 0; i < 10000; i ++) {
        [self incrementAsyncCounter];
        dispatch_semaphore_wait(self.semaphore , DISPATCH_TIME_FOREVER);
        dispatch_async([NRMAStressTestHelper randomDispatchQueue], ^{
           @autoreleasepool {
               [self randomlyExecute];
               [self incrementAsyncEndedCounter];
               dispatch_semaphore_signal(self.semaphore);
           }
        });
    }
    while (CFRunLoopGetCurrent() && self.asyncEndedCounter < self.asyncStartedCounter) {}
}
static NSString* mutex=@"mutex";
- (void)randomlyExecute
{
    @autoreleasepool {
        int options = 3;
        switch (rand() % options) {
            case 0:
                @synchronized(mutex) {
                    self.analytics = nil;
                }
                break;
            case 1:
                @synchronized(mutex) {
                    self.analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:0];
                }
                break;
            case 2:
                [self.analytics setNRSessionAttribute:@"memoryUsage"
                                                value:@1];
                break;
        }
    }
}

@end

