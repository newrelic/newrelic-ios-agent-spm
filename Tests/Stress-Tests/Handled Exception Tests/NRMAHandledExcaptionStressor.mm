//
//  NRMAHandledExcaptionStressor.m
//  NewRelicAgent
//
//  Created by Austin Washington on 7/20/17.
//  Copyright © 2017 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "NRMAStressTestHelper.h"
#import "NRMAHandledExceptions.h"
#import "NRMAAgentConfiguration.h"
#import "NewRelicInternalUtils.h"
#import <objc/runtime.h>
#import "NRAgentTestBase.h"
#import "NRMAAppToken.h"
@interface NRMAHandledExceptionStressor : NRMAAgentTestBase
@property(atomic,strong) NRMAHandledExceptions* handled;
//@property(atomic, strong) NSException* test1;
@property(atomic) unsigned long long asyncStartedCounter;
@property(atomic) unsigned long long asyncEndedCounter;
@property(strong) dispatch_semaphore_t semaphore;
@property(strong) NRMAAnalytics* analytics;
@end

void (*NR__NRMAHexUploader_sendData)(id, SEL,id);

void NR__OVERRIDE_NRMAHexUploader_sendData(id self, SEL _cmd, id data) {
    return;
}

@implementation NRMAHandledExceptionStressor

- (void)setUp {
    [super setUp];
    [self replaceNetCalls];
    NRMAAgentConfiguration* _agentConfiguration = [[NRMAAgentConfiguration alloc] initWithAppToken:[[NRMAAppToken alloc] initWithApplicationToken:@"AAc7b6ef0d0fac0a8c802f74343f23cb47f0dd0ccb"] collectorAddress:@"staging-mobile-collector.newrelic.com" crashAddress:nil];

    self.analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:0];
    self.handled = [[NRMAHandledExceptions alloc] initWithAnalyticsController:_analytics
                                                             sessionStartTime:[NSDate date]
                                                           agentConfiguration:_agentConfiguration
                                                                     platform:@"iOS"
                                                                    sessionId:@"id"];

    NSUInteger procCount = [[NSProcessInfo processInfo] processorCount];
    self.semaphore = dispatch_semaphore_create(procCount);
}         


- (void) replaceNetCalls {
    id clazz = objc_getClass("NRMAHexUploader");
    SEL selector = @selector(sendData:);
    if (clazz) {
        Method m = class_getInstanceMethod(clazz, selector);
        NR__NRMAHexUploader_sendData = (void(*)(id,SEL,id))class_replaceMethod(clazz, selector, (IMP)NR__OVERRIDE_NRMAHexUploader_sendData, method_getTypeEncoding(m));
    }
}

- (void) restoreNetCalls {
    id clazz = objc_getClass("NRMAHexUploader");
    SEL selector = @selector(sendData:);

    if (clazz) {
        Method m = class_getInstanceMethod(clazz, selector);
        class_replaceMethod(clazz, selector, (IMP)NR__NRMAHexUploader_sendData, method_getTypeEncoding(m));
    }
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.

    //one final process clean up all files.
    [self.handled processAndPublishPersistedReports];

        [self restoreNetCalls];
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
        //TESTING STRESSFULLY !!?!?!?!?!
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
    NSLog(@"finished");
}


- (void) randomlyExecute {
    
    @autoreleasepool {
        int options = 2;
        switch (rand() % options) {
            case 0:
                [self.handled onHarvest];
                break;
            case 1:
                @try{
                    @throw [NSException exceptionWithName:@"anything" reason:@"stressfull" userInfo: nil];;
                } @catch(NSException* e) {
                    [self.handled recordHandledException:e];
                }
                break;
            default:
                break;
        }
    }
    
    
}



@end





















