//
//  NRCustomMetricsTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 7/12/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRCustomMetrics.h"
#import "NRMAHarvestableMetric.h"
#import "NRCustomMetricsTests.h"
#import "NRCustomMetrics+private.h"
#import "NRLogger.h"
#import "NRMANamedValueMeasurement.h"
#import "NRMAMeasurements.h"
#import "NRMATaskQueue.h"
@interface NRMATaskQueue ()
+ (NRMATaskQueue*) taskQueue;
@end

@interface NRCustomMetrics ()

+ (BOOL) isValidMetricInput:(NSString*)input;
+ (BOOL) isValidMetricUnit:(NRMetricUnit*)input;

@end
@interface NRMAHarvestableMetric ()
@property(assign) NSMutableArray* collectedValues;
@end

@interface NRMAMetricSet (CustomPrivates)
@property(assign) NSMutableDictionary* metrics;
@end

@implementation NRCustomMetricsTests
- (void) setUp
{
    [super setUp];
    category = @"hello";
    name = @"world";
    
    helper = [[NRMAMeasurementConsumerHelper alloc] initWithType:NRMAMT_NamedValue];

    [NRMAMeasurements initializeMeasurements];
    [NRMAMeasurements addMeasurementConsumer:helper];
    
}
- (void) tearDown
{
    [NRMAMeasurements removeMeasurementConsumer:helper];
    helper = nil;

    [NRMAMeasurements shutdown];
    [super tearDown];
}

- (void) testNRMAMetricRemoveValuesWithAge
{
    NRMAHarvestableMetric* metric1 = [[NRMAHarvestableMetric alloc] initWithMetricName:@"metric1"];
    
    
    int valuecount = 100;
    for(int i = 1; i <= valuecount; i++)
    {
        [metric1.collectedValues addObject:
         @{@"endDate": @0,
         @"value"  : @1,
         @"threadID" : @"0"}];
    }
    NRMAMetricSet* set = [[NRMAMetricSet alloc] init];
    [set.metrics setObject:metric1 forKey:metric1.metricName];
    [set removeMetricsWithAge:1];
    
    XCTAssertTrue([set.metrics count] == 0, @"There shouldn't be any metrics in the set");
    
}

- (void) testBadInputs
{
    XCTAssertNoThrow([[NRCustomMetrics metrics] addValue:nil forMetric:nil], @"shouldn't throw an exception!");

    XCTAssertNoThrow([NRCustomMetrics recordMetricWithName:nil category:nil], @"should just throw a log error");
    
    XCTAssertNoThrow([NRCustomMetrics recordMetricWithName:@"xc" category:@"42"  value:nil valueUnits:@"" countUnits:@""], @"god help us all.");
}

- (void) testRecordMetricsConsistency
{
    [NRCustomMetrics recordMetricWithName:name category:category];

    double delayInSeconds = 2.0;
    __block bool done = false;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!done) {
            XCTFail(@"Test timed out. helper.result was never populated");
        }
    });
   // while (CFRunLoopGetCurrent() && !helper.result) {}; //wait for result to populate

    [NRMATaskQueue synchronousDequeue];

    XCTAssertTrue([helper.result isKindOfClass:[NRMANamedValueMeasurement class]],@"asset the result is a named valed");

    NRMANamedValueMeasurement* measurement = ((NRMANamedValueMeasurement*)helper.result);
    
   // STAssertTrue([set count] == 1, @"There should be only 1 metric in there");
    
    NSString* fullMetricName = [NSString stringWithFormat:@"Custom/%@/%@",category,name];
    XCTAssertNotNil(measurement.name, @"We should find this metric in the set.");
    XCTAssertEqualObjects(measurement.name, fullMetricName, @"name is generated properly.");
    done = true;
}
- (void) testRecordMetricValue
{
    [NRCustomMetrics recordMetricWithName:name category:category value:[NSNumber numberWithInt:200]];

    double delayInSeconds = 2.0;
    __block bool done = NO;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!done) {
            XCTFail(@"Test timed out. helper.result was never populated");
        }
    });

    //
    //while (CFRunLoopGetCurrent() && !helper.result) {}; //wait for result to populate

    [NRMATaskQueue synchronousDequeue];

    XCTAssertTrue([helper.result isKindOfClass:[NRMANamedValueMeasurement class]],@"asset the result is a named valed");
    NRMANamedValueMeasurement* measurement = ((NRMANamedValueMeasurement*)helper.result);
    
    
    XCTAssertEqualObjects(measurement.value, [NSNumber numberWithInteger:200], @"verify value is perserved");
    done = YES;
}

- (void) testRecordMetricWithMetricUnits
{
    
    NSString* fullMetricName = [NSString stringWithFormat:@"Custom/%@/%@[%@]",category,name,kNRMetricUnitsOperations];
    [NRCustomMetrics recordMetricWithName:name
                                 category:category
                                    value:[NSNumber numberWithInt:100]
                               valueUnits:kNRMetricUnitsOperations];

    double delayInSeconds = 2.0;
    __block bool done = NO;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!done) {
            XCTFail(@"Test timed out. helper.result was never populated");
        }
    });
   // while (CFRunLoopGetCurrent() && !helper.result) {}; //wait for result to populate
    [NRMATaskQueue synchronousDequeue];

    XCTAssertTrue([helper.result isKindOfClass:[NRMANamedValueMeasurement class]],@"asset the result is a named valed");
    NRMANamedValueMeasurement* measurement = ((NRMANamedValueMeasurement*)helper.result);
    
    XCTAssertEqualObjects(measurement.name, fullMetricName, @"Names should match");
    done = YES;
}

- (void) testRecordMetricWithMetricAndValueUnits
{
    NSString* fullMetricName = [NSString stringWithFormat:@"Custom/%@/%@[%@|%@]",category,name,kNRMetricUnitsOperations,kNRMetricUnitSeconds];
    [NRCustomMetrics recordMetricWithName:name
                                 category:category
                                    value:[NSNumber numberWithInt:1]
                               valueUnits:kNRMetricUnitsOperations
                               countUnits:kNRMetricUnitSeconds];

    double delayInSeconds = 2.0;
    __block bool done = NO;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!done) {
        XCTFail(@"Test timed out. helper.result was never populated");
        }
    });
    [NRMATaskQueue synchronousDequeue];
  //  while (CFRunLoopGetCurrent() && !helper.result) {}; //wait for result to populate
    
    XCTAssertTrue([helper.result isKindOfClass:[NRMANamedValueMeasurement class]],@"asset the result is a named valed");
    NRMANamedValueMeasurement* measurement = ((NRMANamedValueMeasurement*)helper.result);
    
    
    XCTAssertEqualObjects(measurement.name, fullMetricName, @"Names should match");
    done = YES;
}

- (void) testRecordMetricWithValueUnits
{
    NSString* fullMetricName = [NSString stringWithFormat:@"Custom/%@/%@[|%@]",category,name,kNRMetricUnitSeconds];
    [NRCustomMetrics recordMetricWithName:name
                                 category:category
                                    value:[NSNumber numberWithInt:1]
                               valueUnits:nil
                               countUnits:kNRMetricUnitSeconds];

    double delayInSeconds = 2.0;
    __block bool done = NO;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!done) {
            XCTFail(@"Test timed out. helper.result was never populated");
        }
    });
    //while (CFRunLoopGetCurrent() && !helper.result) {}; //wait for result to populate
    [NRMATaskQueue synchronousDequeue];

    XCTAssertTrue([helper.result isKindOfClass:[NRMANamedValueMeasurement class]],@"asset the result is a named valed");
    NRMANamedValueMeasurement* measurement = ((NRMANamedValueMeasurement*)helper.result);
    
    XCTAssertEqualObjects(measurement.name, fullMetricName, @"Names should match");
    done = YES;
}


- (void) testHarvestAndreinsertingMetrics
{
    NRMAMetricSet* set = [[NRMAMetricSet alloc] init];
    
    for (int i = 0; i < 100; i++) {
        [set addValue:[NSNumber numberWithInt:1]
            forMetric:[NSString stringWithFormat:@"testMetric_%d",i]];
    }

    XCTAssertTrue([[NRCustomMetrics metrics] count] == 0, @"There shouldn't any metrics in here yet.");

    [[NRCustomMetrics metrics] addMetrics:set];
    
    XCTAssertTrue([[NRCustomMetrics metrics] count] == 100, @"There should be 100 metrics in here yet.");
    
    NRMAMetricSet* harvest = [NRCustomMetrics harvest];

    XCTAssertTrue([[NRCustomMetrics metrics]count] == 0, @"There shouldn't any metrics in here yet.");
    
    XCTAssertTrue([harvest count] == 100, @"There should be 100 metrics in here yet.");
}

- (void) testMetricInputs
{
    XCTAssertTrue([NRCustomMetrics isValidMetricInput:@"HelloWorld"]);
    XCTAssertTrue([NRCustomMetrics isValidMetricInput:@"Server_L9"]);
    
    XCTAssertFalse([NRCustomMetrics isValidMetricInput:@"1;DROP TABLE users;"]);
    XCTAssertTrue([NRCustomMetrics isValidMetricInput:@" H e  l l o W o r l d "]);
    
}

- (void) testUnitsInputs
{
    XCTAssertTrue([NRCustomMetrics isValidMetricUnit:kNRMetricUnitPercent]);
    XCTAssertTrue([NRCustomMetrics isValidMetricUnit:kNRMetricUnitSeconds]);
    XCTAssertTrue([NRCustomMetrics isValidMetricUnit:kNRMetricUnitBytes]);
    XCTAssertTrue([NRCustomMetrics isValidMetricUnit:kNRMetricUnitsOperations]);
    XCTAssertTrue([NRCustomMetrics isValidMetricUnit:kNRMetricUnitsBytesPerSecond]);

    XCTAssertFalse([NRCustomMetrics isValidMetricUnit:@"1;DROP TABLE users;"]);
    
}

@end
