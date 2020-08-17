//
//  NRMAMetricTests.m
//  NewRelicAgent
//
//  Created by Jonathan Karon on 5/24/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMetricTests.h"
#import "NRMAHarvestableMetric.h"
#import "NRMAMetricSet.h"

// expose the innards of the metric classes via categories

@interface NRMAHarvestableMetric()
@property (nonatomic, strong) NSMutableArray *collectedValues;
@end

@interface NRMAMetricSet ()
@property (atomic, strong) NSMutableDictionary *metrics;
@end


@implementation NRMAMetricTests

- (void)testNRMAMetricSavesName
{
    NSString *testName = @"hoohah";
    NRMAHarvestableMetric *metric = [[NRMAHarvestableMetric alloc] initWithMetricName:testName];

    XCTAssertEqualObjects(metric.metricName, testName, @"Metric should have name %@ but instead has %@", testName, metric.metricName);
}

- (void)testNRMAMetricSavesOneValue
{
    NRMAHarvestableMetric *metric = [[NRMAHarvestableMetric alloc] initWithMetricName:@"hoohah"];

    NSNumber *testNumber1 = @3.1415927;
    [metric addValue:testNumber1];

    XCTAssertTrue(metric.collectedValues.count == 1, @"Metric should have 1 value but has %lu instead", (unsigned long)metric.collectedValues.count);
    XCTAssertEqualObjects([metric.collectedValues[0] objectForKey:kValueKey], testNumber1,
                          @"Metric should have single value %f but instead has %f",
                          testNumber1.doubleValue, ((NSNumber*)[metric.collectedValues[0] objectForKey:kValueKey]).doubleValue);
}

- (void)testNRMAMetricSavesTwoValuesInOrder
{
    NRMAHarvestableMetric *metric = [[NRMAHarvestableMetric alloc] initWithMetricName:@"hoohah"];

    NSNumber *testNumber1 = @3.1415927;
    NSNumber *testNumber2 = @2.0;
    [metric addValue:testNumber1];
    [metric addValue:testNumber2];

    XCTAssertTrue(metric.collectedValues.count == 2, @"Metric should have 2 values but has %lu instead", (unsigned long)metric.collectedValues.count);
    XCTAssertEqualObjects([metric.collectedValues[0] objectForKey:kValueKey], testNumber1,
                          @"Metric should have position 1 value %f but instead has %f",
                          testNumber1.doubleValue, ((NSNumber *)[metric.collectedValues[0] objectForKey:kValueKey]).doubleValue);
    XCTAssertEqualObjects([metric.collectedValues[1] objectForKey:kValueKey], testNumber2,
                          @"Metric should have position 2 value %f but instead has %f",
                          testNumber2.doubleValue, ((NSNumber *)[metric.collectedValues[1] objectForKey:kValueKey]).doubleValue);
}

// TODO test NRMAMetric.asDictionary (possibly refactor out calculator methods to test in isolation?

// TODO test NRMAMetricSet correctly manages NRMAMetric instances by unique instance per name

// TODO test NRMAMetricSet.asDictionary


@end
