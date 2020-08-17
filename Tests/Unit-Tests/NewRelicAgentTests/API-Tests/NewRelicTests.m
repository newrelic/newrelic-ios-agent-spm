//
//  NewRelicTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 12/2/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMATraceController.h"
#import "NewRelic.h"
@interface NewRelicTests : XCTestCase

@end

@implementation NewRelicTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}


- (void) testBadSelectorMethodTrace
{
    [NRMATraceController startTracingWithName:@"TEST"
                         interactionObject:self];
    XCTAssertNoThrow(
                    [NewRelic startTracingMethod:NSSelectorFromString(@"asdf123__3;.//@@$@!")
                                          object:self
                                           timer:[[NRTimer alloc] init]
                        category:NRTraceTypeDatabase], @"");

    XCTAssertNoThrow(
                    [NewRelic startTracingMethod:nil
                                          object:self
                                           timer:[[NRTimer alloc] init]
                                        category:NRTraceTypeImages],@"");


    [NRMATraceController completeActivityTrace];

}
@end
