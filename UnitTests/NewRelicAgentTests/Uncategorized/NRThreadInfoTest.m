//
//  NRMAThreadInfoTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/22/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRThreadInfoTest.h"
#import "NRMAThreadInfo.h"
@implementation NRMAThreadInfoTest

- (void) testThreadName
{
    NRMAThreadInfo* threadInfo = [[NRMAThreadInfo alloc] init];
    XCTAssertTrue([threadInfo.name isEqualToString:@"Main Thread"], @"threads by default don't have a name?");
    
    NSThread* thread = [[NSThread alloc] initWithTarget:self
                                               selector:@selector(thread)
                                                 object:nil];
    thread.name = @"hello world";
    
    [thread start];
    
}


- (void) thread
{
    @autoreleasepool {
        NRMAThreadInfo* threadInfo = [[NRMAThreadInfo alloc] init];
        XCTAssertTrue([threadInfo.name isEqualToString:@"hello world"], @"These names should match!");
    }
}
@end
