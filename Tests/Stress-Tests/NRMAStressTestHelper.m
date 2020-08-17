//
//  NRMAStressTestHelper.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/11/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAStressTestHelper.h"


const int kNRMAIterations = 500000;
const int kNRMASemaphoreMultiplier = 2;

@implementation NRMAStressTestHelper

+ (dispatch_queue_t) randomDispatchQueue
{
    @autoreleasepool {
        static dispatch_queue_t queue1;
        static dispatch_queue_t queue2;
        static dispatch_queue_t queue3;
        static dispatch_queue_t queue4;

        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            queue1  = dispatch_queue_create("queue1", DISPATCH_QUEUE_CONCURRENT);
            queue2  = dispatch_queue_create("queue2", DISPATCH_QUEUE_CONCURRENT);
            queue3  = dispatch_queue_create("queue3", DISPATCH_QUEUE_CONCURRENT);
            queue4  = dispatch_queue_create("queue4", DISPATCH_QUEUE_CONCURRENT);

        });
        switch (rand() % 4) {
            case 0:


                return queue1;
                break;
            case 1:
                return queue2;
                break;
            case 2:
                return queue3;
                break;
            case 3:
                return queue4;
                break;
            default:
                return queue1;
                break;
        }
    }
}
@end
