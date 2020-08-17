
//
//  MachineMeasurementsTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/30/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import  <OCMock/OCMock.h>
#import "NRMAMeasurements.h"
#import "NRTestHelperConsumer.h"
#import "NRMAMeasurementEngine.h"
#import "NRMANamedValueMeasurement.h"
#import "NRMAHarvestController.h"
#import "NRAgentTestBase.h"
#import "NRTestConstants.h"
#import "NRMAAppToken.h"

@interface NRMAMeasurements (tests)
+ (NRMAMeasurementEngine*) engine;
@end
@interface NRMAHarvester ()
- (void) fireOnHarvest;
- (void) fireOnHarvestBefore;
- (void) connected;
@end

@interface MachineMeasurementsTest : NRMAAgentTestBase
{
    NRMAHarvester* harvester;
    NRMATestHelperConsumer* consumer;
    id mockObject;
    id mockharvestController;
}



@end

@interface NRMAHarvestController ()
+ (void) deinitialize;

@end

@implementation MachineMeasurementsTest

- (void)setUp
{
    [super setUp];
    NRMAAgentConfiguration* agentConfig = [[NRMAAgentConfiguration alloc] initWithAppToken:[[NRMAAppToken alloc] initWithApplicationToken:kNRMA_ENABLED_STAGING_APP_TOKEN]
                                                                          collectorAddress:@"staging-mobile-collector.newrelic.com"
                                                                              crashAddress:nil];
    
    NSMutableArray* harvestAwareObjects = [[NSMutableArray alloc] init];

    mockharvestController = [OCMockObject mockForClass:[NRMAHarvestController class]];
    [[[[mockharvestController stub] classMethod] andReturn:mockharvestController] harvestController];
    [[[mockharvestController stub] andDo:^(NSInvocation *invocation) {
        id harvestAwareObject = nil;
        [invocation getArgument:&harvestAwareObject atIndex:2];
        @synchronized(harvestAwareObjects) {
            [harvestAwareObjects addObject:harvestAwareObject];
        }
        if (harvester) {
            [harvester addHarvestAwareObject:harvestAwareObject];
        }

    }] addHarvestAwareObject:OCMOCK_ANY];

    harvester = [[NRMAHarvester alloc] init];//[[NRHarvestController harvestController] harvester];

    for (id<NRMAHarvestAware> obj in harvestAwareObjects) {
        [harvester addHarvestAwareObject:obj];
    }

    mockObject = [OCMockObject partialMockForObject:harvester];
    [[mockObject stub] connected];
    [[[mockharvestController stub] andReturn:mockObject] harvester];

    int value = 3;
    [[[mockObject stub] andReturnValue:[NSValue value:&value withObjCType:((const char*)@encode(int))]] currentState];

    [NRMAMeasurements initializeMeasurements];
    consumer = [[NRMATestHelperConsumer alloc] initWithType:NRMAMT_NamedValue];
    [NRMAMeasurements addMeasurementConsumer:consumer];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [mockharvestController stopMocking];
    [mockObject stopMocking];
    [NRMAMeasurements removeMeasurementConsumer:consumer];
    [NRMAMeasurements shutdown];
    [NRMAHarvestController deinitialize];
    [super tearDown];
}

- (void) testGenerateMachineMeasurementsOnHarvestBefore
{
    [[NRMAMeasurements engine] onHarvestBefore];
    NSSet* machineSet = [consumer.consumedmeasurements objectForKey:[NSNumber numberWithInteger:NRMAMT_NamedValue]];
    XCTAssertTrue([machineSet count] == 4, @"test that there are the 4 machine measurements");
    for (id obj in machineSet.allObjects) {
        XCTAssertTrue([obj isKindOfClass:[NRMANamedValueMeasurement class]], @"verify they are named value measurements");
    }
}

- (void) testGenerateMachineMeasurementsBeforeHarvest
{

    id myMock = mockObject;

    __block BOOL complete = NO;
    [[[myMock expect] andForwardToRealObject] fireOnHarvestBefore];
    [[[myMock stub] andDo:^(NSInvocation* invocation) {
        [myMock verify];
        NRMAMetricSet* set = [NRMAHarvestController harvestData].metrics;
        XCTAssertTrue([set count],@"test we get metrics before");
        complete = YES;
    }] fireOnHarvest];

    [((NRMAHarvester*) myMock) execute];
        
    
    while (CFRunLoopGetCurrent() && !complete) {
    };
    [myMock stopMocking];
    myMock = nil;
}

@end
