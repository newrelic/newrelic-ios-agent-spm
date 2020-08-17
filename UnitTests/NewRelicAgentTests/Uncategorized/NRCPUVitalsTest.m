//
//  NRMACPUVitalsTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/10/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRCPUVitalsTest.h"
#import "NRMACPUVitals.h"

@implementation NRMACPUVitalsTest

- (void) setUp
{
    [super setUp];
}
- (void) testThreadSafety
{
    dispatch_queue_t queue1 = dispatch_queue_create("queue1", NULL);
    dispatch_queue_t queue2 = dispatch_queue_create("queue2", NULL);
    for (int i = 0; i < 100; i++) {
        dispatch_async(queue1, ^{
            CPUTime innerTime;
            XCTAssertNoThrow([NRMACPUVitals cpuTime:&innerTime],@"assert accessing cputime on separate threads doesn't crash");
        });
    }

    for (int i = 0; i < 100; i++){
        dispatch_async(queue2, ^{
            CPUTime innerTime;
            XCTAssertNoThrow([NRMACPUVitals cpuTime:&innerTime],@"assert accessing cputime on separate threads doesn't crash");
        });
    }
}
@end
