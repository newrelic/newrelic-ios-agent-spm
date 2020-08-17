//
//  NRMAMetricSetTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/8/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "NRMAMetricSet.h"
@interface NRMAMetricSetTest : SenTestCase
@property(atomic,strong) NRMAMetricSet* set;
@end

@implementation NRMAMetricSetTest

- (void)setUp
{
    [super setUp];
    self.set = [[NRMAMetricSet alloc] init];
}

- (void)tearDown
{
    self.set = nil;
    [super tearDown];
}

- (void) testSetHammer
{
    int iterations = 10000;
    for (int i = 0; i < iterations; i++) {
        dispatch_async([self randomQueue], ^{
            [self fireRandomMethod];
        });
        dispatch_async([self randomQueue], ^{
            [self maybeFireReset];
        });
    };
}
- (void) fireRandomMethod
{
//    switch (rand() % 7) {
//        case 0:
            [self addValue];
//            break;
//        case 1:
            [self addexclusiveTime];
//            break;
//        case 2:
//            [self trim];
//            break;
//        case 3:
//            [self.set reset];
//            break;
//        case 4:
//            [self.set JSONObject];
//            break;
//        case 5:
//            [self.set flushMetrics];
//            break;
//        case 6:
            [self addScopedValue];
//            break;
//        default:
//            break;
//    }
}

- (void) maybeFireReset
{
    switch (rand() % 5) {
        case 0:
                [self reset];
            break;
        default:
            break;
    }
}

- (dispatch_queue_t) randomQueue
{
    switch (rand() % 4) {
        case 0:
            return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            break;
        case 1:
            return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            break;
        case 2:
            return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
            break;
        case 3:
            return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
            break;
        default:
            return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            break;
    }
}

- (void) reset {
    dispatch_async([self randomQueue], ^{
        self.set = nil;
        self.set = [[NRMAMetricSet alloc] init];
    });
}


- (void) addScopedValue{
    [self.set addValue:@1 forMetric:@"1" withScope:@"1"];
}
- (void) addValue {

    [self.set addValue:[NSNumber numberWithInt:1]
             forMetric:[NSString stringWithFormat:@"%d",1]];
}

- (void) addexclusiveTime
{
    [self.set addExclusiveTime:[NSNumber numberWithInt:1]
                     forMetric:[NSString stringWithFormat:@"%d",1]
                     withScope:[NSString stringWithFormat:@"%d",1]];
}

- (void) trim
{
    [self.set trimToSize:(NSUInteger)rand()];
}

- (void) count {
    [self.set count];
}
@end
