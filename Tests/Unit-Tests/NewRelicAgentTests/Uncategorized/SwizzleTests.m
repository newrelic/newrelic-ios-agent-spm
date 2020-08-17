//
//  SwizzleTest.m
//  NewRelicAgent
//
//  Created by Saxon D'Aubin on 6/26/12.
//  Copyright (c) 2012 New Relic. All rights reserved.
//

#import "SwizzleTests.h"
#import "NRMAMethodSwizzling.h"
#import <objc/runtime.h>

@interface TestBasest : NSObject
-(int)number;
@end

@implementation TestBasest

-(int)number
{
    return 1;
}

@end

@interface TestBase : TestBasest
@property (atomic) int count;
@end

@implementation TestBase
@synthesize count;


-(int)number
{
    NSLog(@"Class %@", NSStringFromClass([self class]));
    NSLog(@"Super %@", NSStringFromClass([super class]));
    return [super number] + 1;
}

@end


/**************************************************************************
 *                                                                        *
 * Swizzling happens at the class level, so we need to define a new class *
 * for each test that performs a swizzling operation. Otherwise we risk   *
 * leaving classes in a bad state between tests & breaking things in      *
 * weird & not-so-wonderful ways.                                         *
 *                                                                        *
 **************************************************************************/

#define DUMB_TEST_CLASS(name, base) \
@interface name : base \
@end \
\
@implementation name \
@end

#define DUMB_TEST_CLASS_WITH_METHOD(name, base, decl, impl) \
@interface name : base \
decl; \
@end \
\
@implementation name \
decl \
{ \
impl \
} \
@end

#define DUMB_TEST_CLASS_WITH_INCREMENT_METHOD(name, base) \
DUMB_TEST_CLASS_WITH_METHOD(name, base, -(void)increment, self.count++;)

DUMB_TEST_CLASS_WITH_INCREMENT_METHOD(Test01, TestBase)
DUMB_TEST_CLASS(Test02, TestBase)
DUMB_TEST_CLASS_WITH_INCREMENT_METHOD(Test03, TestBase)
DUMB_TEST_CLASS(Test04, TestBase)

static void overrideIncrement(id self, SEL _cmd)
{
    Test01* test = self;
    test.count = 666;
    if ([self respondsToSelector:@selector(orig_increment)]) {
        [self performSelector:@selector(orig_increment)];
    }
}

static int overrideNumber(id self, SEL _cmd) {
    if ([self respondsToSelector:@selector(NR__number)]) {
        return -(int)[self performSelector:@selector(NR__number)];
    }
    return 666;
}

@implementation SwizzleTests

- (void)testNRSwizzleHierarchy01
{
    Test01* test = [[Test01 alloc] init];
    XCTAssertEqual([test number], 2, @"[test number] is incorrect");

    XCTAssertTrue(NRMASwizzleOrAddMethod(test, @selector(number), @selector(NR__number), (IMP)overrideNumber), @"Swizzle failed");

    XCTAssertEqual([test number], -2, @"[test number] is incorrect");

    //
    // Swizzling `number` on the Test class should have no impact on base classes.
    //
    TestBase *testBase = [[TestBase alloc] init];
    XCTAssertEqual([testBase number], 2, @"[testBase number  is incorrect");
    XCTAssertFalse([testBase respondsToSelector:@selector(NR__number)], @"TestBase should not have an NR__number method");

    TestBasest *testBasest = [[TestBasest alloc] init];
    XCTAssertEqual([testBasest number], 1, @"[testBasest number] is incorrect");
    XCTAssertFalse([testBasest respondsToSelector:@selector(NR__number)], @"TestBasest should not have an NR__number method");
}

- (void)testDoubleSwizzle02
{
    Test02* test = [[Test02 alloc] init];
    XCTAssertEqual([test number], 2, @"[test number] is incorrect");

    XCTAssertTrue(NRMASwizzleOrAddMethod(test, @selector(number), @selector(NR__number), (IMP)overrideNumber), @"Swizzle failed");
    XCTAssertEqual([test number], -2, @"[test number] is incorrect");

    XCTAssertFalse(NRMASwizzleOrAddMethod(test, @selector(number), @selector(NR__number), (IMP)overrideNumber), @"Swizzle failed");
    XCTAssertEqual([test number], -2, @"[test number] is incorrect");
}

- (void)testNRMASwizzleOrAddMethod_Existing03
{
    Test03* test = [[Test03 alloc] init];
    [test increment];

    XCTAssertFalse([test respondsToSelector:@selector(orig_increment)], @"Shouldn't respond to selector yet");
    XCTAssertEqual(1, test.count, @"Count should be one");

    NRMASwizzleOrAddMethod(test, @selector(increment), @selector(orig_increment), (IMP)overrideIncrement);

    XCTAssertTrue([test respondsToSelector:@selector(orig_increment)], @"Should respond to orig_increment selector");
    XCTAssertTrue([test respondsToSelector:@selector(increment)], @"Should respond to increment selector");

    [test increment];

    XCTAssertEqual(667, test.count, @"Count should be 667");
}

- (void)testNRMASwizzleOrAddMethod_NewMethod04
{
    Test04* test = [[Test04 alloc] init];

    NRMASwizzleOrAddMethod(test, @selector(increment), @selector(orig_increment), (IMP)overrideIncrement);

    //
    // If `test` does not respond to `increment`, NRSwizzleOrAddMethod doesn't need to alias it as `orig_increment`
    //
    XCTAssertFalse([test respondsToSelector:@selector(orig_increment)], @"Shouldn't respond to orig_increment");
    XCTAssertTrue([test respondsToSelector:@selector(increment)], @"Should respond to increment");

    [test performSelector:@selector(increment)];

    XCTAssertEqual(666, test.count, @"Count should be 666");
}


@end