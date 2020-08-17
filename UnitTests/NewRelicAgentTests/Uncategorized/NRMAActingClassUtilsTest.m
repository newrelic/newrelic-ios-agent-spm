//
//  NRMAActingClassUtilsTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/15/15.
//  Copyright (c) 2015 New Relic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "NRMAActingClassUtils.h"
@interface NRMAActingClassUtilsTest : XCTestCase

@end

@implementation NRMAActingClassUtilsTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testBadData
{
    XCTAssertNoThrow(NRMA_pushActingClass(nil, nil, nil), @"this shouldn't crash");

    XCTAssertNoThrow(NRMA_popActingClass(nil, nil),@"");

    XCTAssertNil(NRMA_popActingClass(nil, nil), @"");

    XCTAssertNoThrow(NRMA_actingClassArray(nil, nil));

    XCTAssertNil(NRMA_actingClassArray(nil, nil));
}


@end
