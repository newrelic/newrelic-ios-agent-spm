//
//  NRMAInternalUtilsTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/2/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NewRelicInternalUtils.h"
#import <OCMock/OCMock.h>
@interface NewRelicInternalUtils ()
+ (void) setMachModel:(NSString*)model;
+ (NSString*) deviceModelViaSysCtrl;
@end

@interface NRMAInternalUtilsTests : XCTestCase

@end

@implementation NRMAInternalUtilsTests

- (void)setUp
{
    [super setUp];
    [NewRelicInternalUtils setMachModel:nil];
}

- (void)tearDown
{
    [NewRelicInternalUtils setMachModel:nil];
    [super tearDown];
}


static BOOL __didExecuteWebCore;
static BOOL __didExecuteWebThread;

- (void) testNotWebThread
{
    XCTAssertFalse([NewRelicInternalUtils isWebViewThread], @"we are not on a web thread");
}


- (void) testWebCore
{
    __didExecuteWebCore = NO;
    NSThread* pretendWebCore = [[NSThread alloc] initWithTarget:self selector:@selector(webCore) object:nil];
    pretendWebCore.name = @"WebCore";
    [pretendWebCore start];

    while (CFRunLoopGetCurrent() && !__didExecuteWebCore) {}
}
- (void) testWebThread
{
    __didExecuteWebThread = NO;
    NSThread* pretendWebThread = [[NSThread alloc] initWithTarget:self selector:@selector(webThread) object:nil];
    pretendWebThread.name = @"WebThread";
    [pretendWebThread start];

    while (CFRunLoopGetCurrent() && !__didExecuteWebThread) {}
}

- (void) webCore
{
    XCTAssertTrue([NewRelicInternalUtils isWebViewThread], @"this should register as a web thread");
    __didExecuteWebCore = YES;
}

- (void) webThread
{
    XCTAssertTrue([NewRelicInternalUtils isWebViewThread], @"this should register as a web thread");
    __didExecuteWebThread = YES;
}

- (void) testDeviceModelViaSysCtrl
{
    id mockNewRelicUtils = [OCMockObject niceMockForClass:[NewRelicInternalUtils class]];
    [[[mockNewRelicUtils expect] classMethod] deviceModelViaSysCtrl];

    NSString* deviceModel = [NewRelicInternalUtils deviceModel];

    XCTAssertNotNil(deviceModel, @"");
    XCTAssertNoThrow([mockNewRelicUtils verify], @"");

    [mockNewRelicUtils stopMocking];
}

- (void) testDeviceModeViaSysCtrlNil
{
    id mockNewRelicUtils = [OCMockObject niceMockForClass:[NewRelicInternalUtils class]];

    [[[[mockNewRelicUtils stub] classMethod] andReturn:nil] deviceModelViaSysCtrl];

    XCTAssertNotNil([NewRelicInternalUtils deviceModel], @"");

    [mockNewRelicUtils stopMocking];
}

@end
