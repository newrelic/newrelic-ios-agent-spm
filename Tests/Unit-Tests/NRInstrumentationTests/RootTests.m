//
//  NRInstrumentationTests.m
//  NRInstrumentationTests
//
//  Created by Bryce Buchanan on 1/16/15.
//  Copyright (c) 2015 New Relic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "RootTests.h"
#import "NRMAMethodProfiler.h"


@implementation RootTests

- (void)setUp {
    [super setUp];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NRMAMethodProfiler sharedInstance] startMethodReplacement];
    });
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


@end
