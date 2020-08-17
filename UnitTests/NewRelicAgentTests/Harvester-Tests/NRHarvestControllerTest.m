//
//  NRMAHarvestController.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/18/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAHarvestController.h"
#import "NRTestConstants.h"
#import "NRMAMethodSwizzling.h"
#import <OCMock/OCMock.h>
#import <objc/runtime.h>
#import "NRAgentTestBase.h"
#import "NRMAMeasurements.h"
#import "NRMAAppToken.h"

@interface NRMAHarvestAwareTester : NSObject <NRMAHarvestAware>
@end
@implementation NRMAHarvestAwareTester

- (void) onHarvest
{
    @throw [NSException exceptionWithName:@"onHarvest" reason:@"" userInfo:nil];
}
- (void) onHarvestBefore
{
    @throw [NSException exceptionWithName:@"onHarvest" reason:@"" userInfo:nil];
}
- (void) onHarvestComplete
{
    @throw [NSException exceptionWithName:@"onHarvest" reason:@"" userInfo:nil];
}

- (void) onHarvestError
{
    @throw [NSException exceptionWithName:@"onHarvest" reason:@"" userInfo:nil];
}

- (void) onHarvestStart
{
    @throw [NSException exceptionWithName:@"onHarvest" reason:@"" userInfo:nil];
}

- (void) onHarvestStop
{
    @throw [NSException exceptionWithName:@"onHarvest" reason:@"" userInfo:nil];
}


@end

@interface NRMAHarvestControllerTest : NRMAAgentTestBase
{
}
@end

@interface NRMAHarvester (test)
- (void) clearStoredHarvesterConfiguration;
- (NRMAHarvesterConnection*)connection;
@end


@implementation NRMAHarvestControllerTest

- (void)setUp
{
    [super setUp];
    
    // Put setup code here; it will be run once, before the first test case.
    NRMAAgentConfiguration* agentConfig = [[NRMAAgentConfiguration alloc] initWithAppToken:[[NRMAAppToken alloc] initWithApplicationToken:kNRMA_ENABLED_STAGING_APP_TOKEN]
                                                                          collectorAddress:KNRMA_TEST_COLLECTOR_HOST
                                                                              crashAddress:nil];
    [NRMAHarvestController initialize:agentConfig];
    [[[NRMAHarvestController harvestController] harvester] clearStoredHarvesterConfiguration];
    [[[NRMAHarvestController harvestController] harvester] execute];
    [NRMAMeasurements initializeMeasurements];
    while (CFRunLoopGetCurrent() && [[NRMAHarvestController harvestController] harvester].currentState == NRMA_HARVEST_UNINITIALIZED) {};
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [NRMAMeasurements shutdown];
    [NRMAHarvestController stop];
    [super tearDown];
}
- (void) testVerifyCollectorTimestamp
{
    [[[NRMAHarvestController harvestController] harvester] execute];
    NSURLRequest* request = [[[[NRMAHarvestController harvestController] harvester] connection] createDataPost:@"test"];
    
    NSString* timestampHeader = request.allHTTPHeaderFields[kCONNECT_TIME_HEADER];
    XCTAssertNotNil(timestampHeader, @"");
}


- (void) testHarvestControllerRecovery
{
    NRMAHarvestController* controller = [NRMAHarvestController harvestController];
    NRMAHarvestTimer* timer = [controller harvestTimer];
    NRMAHarvester* harvester =  [controller harvester];

    [NRMAHarvestController recovery];

    NRMAHarvestController* recoveredController = [NRMAHarvestController harvestController];
    NRMAHarvestTimer* recoveredTimer = [recoveredController harvestTimer];
    NRMAHarvester* recoveredHarvester = [recoveredController harvester];

    XCTAssertFalse(timer.timer.isValid, @"verify timer is invalidated");
    XCTAssertFalse(timer == recoveredTimer, @"verify the timer was reset");
    XCTAssertFalse(harvester == recoveredHarvester, @"verify the harvester was reset");
    XCTAssertFalse(controller == recoveredController, @"verify the controller was reset");

    timer = nil;
    harvester = nil;
    controller = nil;

}


- (void) testHarvestAwareException
{
    NRMAHarvestAwareTester* haware = [NRMAHarvestAwareTester new];
    [NRMAHarvestController addHarvestListener:haware];

    XCTAssertNoThrow([[[NRMAHarvestController harvestController] harvester] execute], @"assert no crash when harvest aware executes");

}

@end
