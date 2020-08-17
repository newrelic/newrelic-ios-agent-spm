//
//  NRThreadLocalStoreTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/14/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAThreadLocalStore.h"
#import "NewRelicInternalUtils.h"
#import "NRMATrace.h"
#import "NRLogger.h"

@interface NRMAThreadLocalStore (test)
+ (int) prepareSameThread:(NSMutableArray*)stack child:(NRMATrace*)child withParent:(NRMATrace*)parent;
+ (void)setThreadRootTrace:(NRMATrace *)rootTrace;
+ (BOOL)popCurrentTraceIfEqualTo:(NRMATrace*)trace returningParent:(NRMATrace **)parent;
+ (NSMutableArray*)threadLocalStack ;
@end

@interface NRThreadLocalStoreTests : XCTestCase
@property(strong) NRMATrace* parentTrace;
@property(strong) NRMATrace* rootTrace;
@end

@implementation NRThreadLocalStoreTests

- (void)setUp
{
    [super setUp];
    [NRLogger setLogLevels:NRLogLevelNone];
    self.rootTrace = [[NRMATrace alloc] initWithName:@"UI_Thread" traceMachine:nil];
    self.parentTrace = [[NRMATrace alloc] initWithName:@"blah" traceMachine:nil];
    self.parentTrace.entryTimestamp = 0;
    self.parentTrace.exitTimestamp = 10;
    [NRMAThreadLocalStore setThreadRootTrace:self.rootTrace];
    [NRMAThreadLocalStore pushChild:self.parentTrace forParent:self.rootTrace];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testNormalMethod
{
    
    NRMATrace* child = [[NRMATrace alloc] initWithName:@"normal" traceMachine:nil];
    child.entryTimestamp = 5; //we start while the parent is running!

    int error = [NRMAThreadLocalStore prepareSameThread:[NRMAThreadLocalStore threadLocalStack]
                                                child:child
                                           withParent:self.parentTrace];

    XCTAssertTrue(error == 0, @"we should not encounter an error for pushing a child trace.");
}

- (void)testSeriallyDispatchedMethod
{
    NRMATrace* parent;
    [NRMAThreadLocalStore popCurrentTraceIfEqualTo:self.parentTrace returningParent:&parent];
    NRMATrace* child = [[NRMATrace alloc] initWithName:@"serialChild" traceMachine:nil];
    child.entryTimestamp = 15; //we start after the parent ended!

    int error = [NRMAThreadLocalStore prepareSameThread:[NRMAThreadLocalStore threadLocalStack]
                                                child:child
                                           withParent:self.parentTrace];

    XCTAssertTrue(error == 0, @"we should not encounter an error for pushing a serial trace on to the same thread");
}

- (void) testThreadStoreStability
{
    XCTAssertNoThrow([self stressThreadLocalDictionary],@"thread dictionary should be stable when calling pushChild: and destroyStore");
}
- (void) stressThreadLocalDictionary
{
    int iterations = 100000;
    __block int iterationsCompleted = 0;

    int destroysStarted = 0;
    __block int destroysCompleted = 0;

    for (int i = 0; i < iterations; i++) {
        dispatch_async([self randomQueue], ^{
            if (rand() %2 == 0) {
                NRMATrace* parent = [NRMAThreadLocalStore threadLocalTrace];
                if (!parent) {
                    parent = [[NRMATrace alloc] initWithName:@"parent" traceMachine:nil];
                    parent.entryTimestamp = NRMAMillisecondTimestamp();
                    [NRMAThreadLocalStore setThreadRootTrace:parent];
                }
                NRMATrace* child  = [[NRMATrace alloc] initWithName:@"child" traceMachine:nil];
                child.entryTimestamp = NRMAMillisecondTimestamp();
                [NRMAThreadLocalStore pushChild:child forParent:parent];
            }
            @synchronized(self) {
                iterationsCompleted++;
            }
        });

        if (rand() % 3 == 0) {
            destroysStarted++;
            dispatch_async([self randomQueue], ^() {
                [NRMAThreadLocalStore destroyStore];
                @synchronized(self) {
                    destroysCompleted++;
                }
            });
        }
    }

    while (CFRunLoopGetCurrent() && ((iterationsCompleted < iterations) || (destroysCompleted < destroysStarted))) {}
}

- (dispatch_queue_t) randomQueue
{
    int rand = random()%4;
    switch (rand) {
        case 0:
            return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            break;
        case 1:
            return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            break;
        case 2:
            return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
            break;
        case 3:
            return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
            break;
        default:
            break;
    }
    return dispatch_get_main_queue();
}
@end
