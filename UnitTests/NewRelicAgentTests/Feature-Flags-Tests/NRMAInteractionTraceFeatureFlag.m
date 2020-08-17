//
//  NRMAInteractionTraceFeatureFlag.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/2/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "NewRelic.h"
#import "NRMATraceMachine.h"
#import "NRMATraceController.h"
@interface NRMAInteractionTraceFeatureFlag : XCTestCase

@end

@implementation NRMAInteractionTraceFeatureFlag

- (void)setUp {
    [super setUp];
    [NewRelic disableFeatures:NRFeatureFlag_InteractionTracing];
}

- (void)tearDown {
    [NewRelic enableFeatures:NRFeatureFlag_InteractionTracing];
    [super tearDown];
}

- (void) testNoTraceMachineInitialized { 
    id mockTraceMachine = [OCMockObject mockForClass:[NRMATraceMachine class]];

    (void) [[mockTraceMachine expect] initWithRootTrace:OCMOCK_ANY];

    [NewRelic startInteractionWithName:@"HELLO WORLD"]; //one way to start a interaction

    UIViewController* testController = [[UIViewController alloc] init];

    [testController viewDidLoad]; //a different way to start an interaction

    XCTAssertThrows([mockTraceMachine verify], @"initWithRootTrace: was called.");

    testController = nil;

    [mockTraceMachine stopMocking];
}

- (void) testNoTraceWithGCD {
    __block BOOL finished = NO;
    dispatch_queue_t queue = dispatch_get_current_queue();
    [NewRelic startInteractionWithName:@"HELLO WORLD"]; //one way to start a interaction
    id mockTraceController = [OCMockObject mockForClass:[NRMATraceController class]];
    [[[mockTraceController expect] classMethod] enterMethod:OCMOCK_ANY name:OCMOCK_ANY];
    [[[mockTraceController expect] classMethod] exitMethod];
    [[[mockTraceController expect] classMethod] enterMethod:[OCMArg anySelector]
                                            fromObjectNamed:OCMOCK_ANY
                                                parentTrace:OCMOCK_ANY
                                              traceCategory:[OCMArg anyPointer]
                                                  withTimer:OCMOCK_ANY];
    
     dispatch_async(queue, ^(){});

    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0), ^{});

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{});

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{finished = YES;});

    dispatch_apply(1, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0), ^(size_t t) {});

    while (CFRunLoopGetCurrent() && finished == NO) {}

    XCTAssertThrows([mockTraceController verify], @"one of the methods above was called!");

    [mockTraceController stopMocking];
}


@end
