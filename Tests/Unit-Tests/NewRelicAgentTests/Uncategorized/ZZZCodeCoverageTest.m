//
//  ZZZCodeCoverageTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/7/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface ZZZCodeCoverageTest : XCTestCase

@end

@implementation ZZZCodeCoverageTest

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

extern void __gcov_flush();

-(void)testThatIsntReallyATest
{
    NSLog(@"FLUSHING GCOV FILES");
    __gcov_flush();
}


@end
