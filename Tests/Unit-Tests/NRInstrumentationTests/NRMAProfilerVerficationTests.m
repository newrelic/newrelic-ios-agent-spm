//
//
//  NRMAProfilerVerficationTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/15/15.
//  Copyright (c) 2015 New Relic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "NRMATraceController.h"
#import "NRMAMethodProfiler.h"
#import "NRMeasurementConsumerHelper.h"
#import "NRMATaskQueue.h"
#import "NRMAMeasurements.h"
#import "NRMACustomTrace.h"
#import "NRMAMethodProfiler.h"
#import "RootTests.h"
#import <OCMock/OCMock.h>
#import "NRMAHarvestController.h"
#import "NRMAActivityTraceMeasurement.h"
@interface NRImage : UIImage

@end

@implementation NRImage

@end

@interface NRMATaskQueue ()
+ (NRMATaskQueue*) taskQueue;
@end

@interface NRMAProfilerVerficationTests : RootTests{
    id harvestConfigurationObject;
}
@property(strong) NRMAMeasurementConsumerHelper* helper;
@end

@implementation NRMAProfilerVerficationTests

- (void)setUp {
    [super setUp];
    _helper = [[NRMAMeasurementConsumerHelper alloc] initWithType:NRMAMT_Activity];

    harvestConfigurationObject = [OCMockObject niceMockForClass:[NRMAHarvestController class]];
    NRMAHarvesterConfiguration* config = [[NRMAHarvesterConfiguration alloc] init];
    config.collect_network_errors = YES;
    config.data_report_period= 60;
    config.error_limit = 3;
    config.report_max_transaction_age = 5;
    config.report_max_transaction_count = 2000;
    config.response_body_limit = 1024;
    config.stack_trace_limit = 2000;
    config.activity_trace_max_send_attempts = 2;
    config.activity_trace_min_utilization = 0; //need to set this to 0 so we can capture all the stuff.
    [[[harvestConfigurationObject stub] andReturn:config] configuration];

    [NRMAMeasurements initializeMeasurements];
    [NRMAMeasurements addMeasurementConsumer:_helper];

    NSBundle *bundle = [NSBundle bundleForClass:[NRMATaskQueue class]];
}

- (void)tearDown {
    [NRMAMeasurements removeMeasurementConsumer:_helper];
    [NRMAMeasurements shutdown];
    [harvestConfigurationObject stopMocking];
    _helper = nil;
    [super tearDown];
}



//@"UIImage":@[@"imageNamed:",@"imageWithContentsOfFile:",@"imageWithData:",@"imageWithData:scale:",@"initWithContentsOfFile:",@"initWithData:",@"initWithData:scale:"],
- (void) testValidUIImageInteraction {
    [NRMATraceController startTracing:YES];
    [UIImage imageWithData:[[NSData alloc] init]];
    [[UIImage alloc] initWithData:[[NSData alloc]init]];
    [UIImage imageNamed:@"asfasf"];
    [UIImage imageWithContentsOfFile:@""];
    [UIImage imageWithData:[[NSData alloc]init] scale:1];
    [[UIImage alloc] initWithData:[[NSData alloc] init] scale:1.0];

    [NRMATraceController completeActivityTrace];
    [NRMATaskQueue synchronousDequeue];

    XCTAssertNotNil(self.helper.result, @"we should have found a interaction trace");
    NRMAActivityTraceMeasurement* traceMeasurement = self.helper.result;

    XCTAssertTrue([traceMeasurement.rootTrace.children count] == 6, @"");


    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:@{
                                   @"UIImage#imageWithData:"           :@1,
                                   @"UIImage#initWithData:"            :@1,
                                   @"UIImage#imageNamed:"              :@1,
                                   @"UIImage#imageWithContentsOfFile:" :@1,
                                   @"UIImage#imageWithData:scale:"     :@1,
                                   @"UIImage#initWithData:scale:"      :@1}];

    for (NRMATrace* trace in traceMeasurement.rootTrace.children.allObjects) {
        XCTAssertNotNil(dict[trace.name],@"%@ unexpected trace in interaction",trace.name);
        [dict removeObjectForKey:trace.name];
    }

    XCTAssertTrue([dict count] == 0 , @"%@ were not found in the trace",dict);
}

- (void) testUIViewControllerInteraction {

    UIViewController* vc = [[UIViewController alloc] init];

    [vc viewDidLoad];
    [vc viewWillAppear:NO];
    [vc viewDidAppear:NO];
    [vc viewWillLayoutSubviews];
    [vc viewDidLayoutSubviews];
    [vc viewWillDisappear:NO];
    [vc viewDidDisappear:NO];
    [NRMATraceController completeActivityTrace];
    
    [NRMATaskQueue synchronousDequeue];

    XCTAssertNotNil(self.helper.result, @"");
    NRMAActivityTraceMeasurement* interaction = self.helper.result;

    XCTAssertTrue([interaction.rootTrace.children count] == 7, @"");

    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                @"UIViewController#viewDidLoad"            :@1,
                                                                                @"UIViewController#viewWillAppear:"        :@1,
                                                                                @"UIViewController#viewDidAppear:"         :@1,
                                                                                @"UIViewController#viewWillLayoutSubviews" :@1,
                                                                                @"UIViewController#viewDidLayoutSubviews"  :@1,
                                                                                @"UIViewController#viewDidDisappear:"      :@1,
                                                                                @"UIViewController#viewWillDisappear:"     :@1}];
    
    for (NRMATrace* trace in interaction.rootTrace.children.allObjects) {
        XCTAssertNotNil(dict[trace.name],@"%@ unexpected trace in interaction",trace.name);
        [dict removeObjectForKey:trace.name];
    }
    
    XCTAssertTrue([dict count] == 0 , @"%@ were not found in the trace",dict);

}

- (void) testNSJSONSerializationInteraction
{
    NSInputStream* stream = [[NSInputStream alloc] initWithData:[@"{\"asdf\":\"asdf\"}" dataUsingEncoding:NSUTF8StringEncoding]];
    [stream open];

    NSOutputStream* outputStream = [[NSOutputStream alloc] initToMemory];
    [outputStream open];


    [NRMATraceController startTracing:YES];
    //these values need to have valid data passed to them or else they will throw
    // a runtime error.
    [NSJSONSerialization JSONObjectWithData:[[NSData alloc]init]
                                    options:NSJSONReadingAllowFragments
                                      error:nil];
    [NSJSONSerialization JSONObjectWithStream:stream
                                      options:NSJSONReadingAllowFragments
                                        error:nil];
    [NSJSONSerialization dataWithJSONObject:@{@"hello":@"world"}
                                    options:NSJSONWritingPrettyPrinted
                                      error:nil];
    [NSJSONSerialization writeJSONObject:@{@"hello":@"world"}
                                toStream:outputStream
                                 options:NSJSONWritingPrettyPrinted
                                   error:nil];
    [NRMATraceController completeActivityTrace];
    [NRMATaskQueue synchronousDequeue];

    XCTAssertNotNil(self.helper.result, @"");
    NRMAActivityTraceMeasurement* interaction = self.helper.result;

    XCTAssertTrue([interaction.rootTrace.children count] == 4, @"");

    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                @"NSJSONSerialization#JSONObjectWithData:options:error:"        :@1,
                                                                                @"NSJSONSerialization#JSONObjectWithStream:options:error:"     :@1,
                                                                                @"NSJSONSerialization#dataWithJSONObject:options:error:"       :@1,
                                                                                @"NSJSONSerialization#writeJSONObject:toStream:options:error:" :@1}];
    
    for (NRMATrace* trace in interaction.rootTrace.children.allObjects) {
        XCTAssertNotNil(dict[trace.name],@"%@ unexpected trace in interaction",trace.name);
        [dict removeObjectForKey:trace.name];
    }
    
    XCTAssertTrue([dict count] == 0 , @"%@ were not found in the trace",dict);
    [stream close];
    [outputStream close];

}


@end
