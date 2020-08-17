//
//  NSObject+NRMAAssociatedObjectTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/29/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAActingClassUtils.h"
#import "NRMAClassDataContainer.h"
@interface NSObject_NRMAAssociatedObjectTest : XCTestCase
{
    NSMutableArray* blah;
}
@end

@implementation NSObject_NRMAAssociatedObjectTest

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
    blah = [[NSMutableArray alloc] init];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    blah = nil;
    [super tearDown];
}
//
//- (void)testExample
//{
//    STFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
//}
//
- (void) testActingClass
{
    XCTAssertNoThrow(NRMA_popActingClass(blah,NSStringFromSelector(_cmd)), @"empty array shouldn't crash when popping");
}


- (void) testAssociatedObject
{
    __weak NSMutableArray* actingClassArray = NRMA_actingClassArray(blah,NSStringFromSelector(_cmd));
    
    XCTAssertEqualObjects(actingClassArray, NRMA_actingClassArray(blah,NSStringFromSelector(_cmd)), @"acting class array should maintain");
}

- (void) testAddAssocatedObjects
{
    NRMA_pushActingClass(blah,NSStringFromSelector(_cmd),[blah class]);
    XCTAssertEqual([NRMA_actingClassArray(blah,NSStringFromSelector(_cmd)) count], (NSUInteger)1, @"one object in acting class array");

    XCTAssertEqual(((NRMAClassDataContainer*)[NRMA_actingClassArray(blah,NSStringFromSelector(_cmd)) firstObject]).storedClass, [blah class], @"first object should equal class");
    XCTAssertEqualObjects(NRMA_actingClass(blah,NSStringFromSelector(_cmd)), [blah class], @"acting class should be current class");
    
    NRMA_pushActingClass(blah,NSStringFromSelector(_cmd),[blah superclass]);
    
    XCTAssertEqual(NRMA_actingClass(blah,NSStringFromSelector(_cmd)), [blah superclass], @"acting class should now equal super class");
    
    NRMA_popActingClass(blah,NSStringFromSelector(_cmd));

    XCTAssertEqual( NRMA_actingClass(blah,NSStringFromSelector(_cmd)), [blah class], @"acting class should be self class");
}



@end
