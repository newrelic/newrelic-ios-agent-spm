//
//  NRMATHarvestableVitalsTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 11/18/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestableVitals.h"
#import <XCTest/XCTest.h>

@interface NRMATHarvestableVitalsTest : XCTestCase

@end

@implementation NRMATHarvestableVitalsTest

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

- (void) testThreadSafe
{
    NSMutableDictionary* blah = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* blub = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < 1000; i++) {
        [blah setObject:@"asd" forKey:[NSString stringWithFormat:@"%d",i]];
    }
    dispatch_queue_t queue = dispatch_queue_create("blah_queue", NULL);
    dispatch_async(queue, ^{
        NRMAHarvestableVitals* vitals = [[NRMAHarvestableVitals alloc] initWithCPUVitals:blah memoryVitals:blub];
        XCTAssertNoThrow([vitals JSONObject], @"");;


    });

    for (int i = 1000; i < 2000; i++) {
        //this will trigger an exception while -[vitals JSONObject] is processing.
        //if blah and blub aren't copied.
        [blah setObject:@"asd" forKey:[NSString stringWithFormat:@"%d",i]];
    }
}

@end
