
//
//  NRMAThreadInfoTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 12/2/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAThreadInfo.h"
#import "NRGCDOverride.h"
#import "NRAgentTestBase.h"
#import "NRMATraceController.h"
#import "NRMAMeasurements.h"



@interface NRMAThreadInfo ()
+ (NSMutableDictionary*) threadNames;
+ (void) addThreadName:(NSString*)name forKey:(id)key;
+ (NSString*) threadNameForKey:(id)key;
@end
@interface NRMAThreadInfoTests : XCTestCase

@end

@implementation NRMAThreadInfoTests

- (void)setUp
{
    [super setUp];
    [NRMAThreadInfo clearThreadNames];
    //one of the tests will cause the measurementEngine to initialize
    //let's take control of that so we can properly shut it down.
    [NRMAMeasurements initializeMeasurements];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [NRMAMeasurements shutdown];
    [super tearDown];
}

- (void) testInit
{
    NRMAThreadInfo* threadInfo = nil;
    XCTAssertNoThrow( threadInfo = [[NRMAThreadInfo alloc] init], @"should successfully create an object");
    XCTAssertEqualObjects(threadInfo.name, @"Main Thread", @"the first thread should be the main thread.");
}


- (void) testNonMainThread
{
    [NSThread detachNewThreadSelector:@selector(nonMainThreadInitHelper) toTarget:self withObject:nil];
}

- (void) nonMainThreadInitHelper
{
    @autoreleasepool {

    NRMAThreadInfo* threadInfo = nil;
    XCTAssertNoThrow(threadInfo = [[NRMAThreadInfo alloc] init], @"should successfully create an object");
    XCTAssertEqualObjects(threadInfo.name, @"Worker Thread #1", @"");
    
    NSLog(@"%@",threadInfo);
    }
}

- (void) testDispatchAsync
{
    [NRMATraceController startTracingWithName:@"TestTrace" interactionObject:self];
    __block BOOL done = NO;
    dispatch_queue_t queue = dispatch_queue_create("", NULL);
    dispatch_async(queue,^(){
//        NRMAThreadInfo* threadInfo = nil;
//        STAssertNoThrow(threadInfo = [[NRMAThreadInfo alloc] init], @"should successfully create an object");

        done = YES;
    });

    while (CFRunLoopGetCurrent() && !done) {};
    [NRMATraceController completeActivityTrace];
}

- (void) testThreadDictionaryThreadSafety
{
    [NSThread detachNewThreadSelector:@selector(threadSafetyHelper) toTarget:self withObject:nil];
    for ( int i = 0; i < 10000; i++ ) {
            [NRMAThreadInfo addThreadName:@"hello" forKey:[NSNumber numberWithInt:i]];
    }
}

- (void) threadSafetyHelper
{
    @autoreleasepool {
    for ( int i = 0; i < 10000; i++ ) {
            [NRMAThreadInfo addThreadName:@"Hello" forKey:[NSString stringWithFormat:@"hello_%d",i]];
    }
    }
}

@end
