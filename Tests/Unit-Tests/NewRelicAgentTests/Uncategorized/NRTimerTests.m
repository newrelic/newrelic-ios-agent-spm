//
//  NRTimerTests.m
//  NewRelicAgent
//
//  Created by Saxon D'Aubin on 6/26/12.
//  Copyright (c) 2012 New Relic. All rights reserved.
//

#import "NRTimerTests.h"
#import "NRTimer.h"

@implementation NRTimerTests

-(void)test
{
    NRTimer* timer = [[NRTimer alloc] init];
    [NSThread sleepForTimeInterval:.5];
    [timer stopTimer];
    
    XCTAssertTrue([timer timeElapsedInSeconds] - 0.5 < 20, @"Timer elapsed time should be ~500 ms");
    
    XCTAssertTrue([timer startTimeInMillis] > 0, @"");
    XCTAssertTrue([timer endTimeInMillis] > [timer startTimeInMillis], @"");
}

@end
