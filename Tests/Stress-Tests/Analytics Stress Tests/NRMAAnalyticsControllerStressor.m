//
//  NRMAAnalyticsControllerStressor.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 3/24/15.
//  Copyright (c) 2015 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAAnalytics.h"
#import "NRMAStressTestHelper.h"

@interface NRMAAnalyticsControllerStressor : XCTestCase
{
    NSArray* kSessionAttributeNames;
}
@property(atomic,strong) NRMAAnalytics* analytics;
@property(atomic) unsigned long long asyncStartedCounter;
@property(atomic) unsigned long long asyncEndedCounter;
@property(strong) dispatch_semaphore_t semaphore;
@end



@implementation NRMAAnalyticsControllerStressor

- (void)setUp {
    [super setUp];
    kSessionAttributeNames = @[@"1234", @"Hello", @"Pew",@"Test",@"Red",@"Yellow",@"Blue"];
    self.analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:0];
    NSUInteger procCount = [[NSProcessInfo processInfo] processorCount];
    self.semaphore = dispatch_semaphore_create(procCount * kNRMASemaphoreMultiplier);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
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

- (void) testStress {
    XCTAssertNoThrow([self stress],
                     @"Failed stress test");
}

- (void) stress {
    int interactions = kNRMAIterations;
    for (int i = 0; i < interactions; i++) {
        @autoreleasepool {
            [self incrementAsyncCounter];
            //These semaphores prevent the dispatch_async calls from blowing out the stack
            //they would otherwise get queued faster than they could be execute
            //thus creating a huge growth in heap size.
            dispatch_semaphore_wait(self.semaphore,
                                    DISPATCH_TIME_FOREVER);
            dispatch_async([NRMAStressTestHelper randomDispatchQueue], ^{
                @autoreleasepool {
                    [self randomlyExecute];
                    [self incrementAsyncEndedCounter];
                    dispatch_semaphore_signal(self.semaphore);
                }
            });

            [self incrementAsyncCounter];
            dispatch_async([NRMAStressTestHelper randomDispatchQueue], ^{
                @autoreleasepool {
                    [self randomlyCleanup];
                    [self incrementAsyncEndedCounter];
                    dispatch_semaphore_signal(self.semaphore);
                }
            });
        }
    }
    while (CFRunLoopGetCurrent() && self.asyncEndedCounter < self.asyncStartedCounter) {}
}

- (void)randomlyExecute
{
    @autoreleasepool {
        int options = 11;
        NSString* name = kSessionAttributeNames[rand()%[kSessionAttributeNames count]];
        switch ( rand() % options ) {
            case 0:
                [self.analytics addEventNamed:@"blah" withAttributes:@{@"pewpew":@"fasdf", @"asdf":@6}];
                break;
            case 1:
                [self.analytics analyticsJSONString];
                break;
            case 2:
                [self.analytics sessionWillEnd];
                break;
            case 3:
                [self.analytics setSessionAttribute:name value:@1234 persistent:YES];
                break;
            case 4:
                [self.analytics setSessionAttribute:name value:@1234 persistent:NO];
                break;
            case 5:
                [self.analytics incrementSessionAttribute:name value:@1];
                break;
            case 6:
                [self.analytics setSessionAttribute:name value:@"world"];
                break;
            case 7:
                [self.analytics incrementSessionAttribute:name value:@1 persistent:YES];
                break;
            case 8:
                [self.analytics incrementSessionAttribute:name value:@1 persistent:NO];
                break;
            case 9:
                [self.analytics removeSessionAttributeNamed:name];
                break;
            case 10:
                [self.analytics addInteractionEvent:name interactionDuration:rand()];
            default:
                break; 
        }
    }
}

- (void) randomlyCleanup {
    int options = 4;
    switch (rand() % options) {
        case 0:
            [NRMAAnalytics clearDuplicationStores];
            break;
        case 1:
            [NRMAAnalytics getLastSessionsAttributes];
            break;
        case 2:
            [NRMAAnalytics getLastSessionsEvents];
            break;
        case 3:
            [self.analytics clearLastSessionsAnalytics];
            break;
        default:
            break;
    }
}
@end
