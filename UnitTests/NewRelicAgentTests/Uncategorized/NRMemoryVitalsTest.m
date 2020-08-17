//
//  NRMAMemoryVitalsTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/10/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMemoryVitalsTest.h"
#import "NRMAMemoryVitals.h"

@implementation NRMAMemoryVitalsTest

- (void) testThreadSafety
{
    dispatch_queue_t queue1 = dispatch_queue_create("queue1", NULL);
    dispatch_queue_t queue2 = dispatch_queue_create("queue2", NULL);
    for (int i = 0; i < 100; i++) {
        dispatch_async(queue1, ^{
            XCTAssertNoThrow([NRMAMemoryVitals memoryUseInMegabytes], @"assert call doesn't crash due to thread safety issues");
        });
    }

    for (int i = 0; i < 100; i++) {
        dispatch_async(queue2, ^{
            XCTAssertNoThrow([NRMAMemoryVitals memoryUseInMegabytes], @"assert call doesn't crash due to thread safety issues");
        });
    }
}
@end
