//
//  NRMAHarvesterStateTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/29/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//
#import "NRMAHarvester.h"
#import "NRHarvesterStateTest.h"

@implementation TestHarvester
- (void) execute
{
    [super execute];
}

- (void) transition:(NRMAHarvesterState)state
{
    stateDidChange = false;
    [super transition:state];
}

- (void) uninitialized
{
    if (_agentConfiguration == nil) {
        NRLOG_ERROR(@"Agent configuration unavailable.");
        return;
    }
    
    connection.connectionInformation = [NRMAAgentConfiguration connectionInformation];
    connection.connectionInformation.applicationInformation.appVersion =@"1.0";
    connection.connectionInformation.applicationInformation.appName = @"test";
    connection.connectionInformation.applicationInformation.bundleId = @"com.test";
    connection.applicationToken = _agentConfiguration.applicationToken;
    connection.collectorHost = _agentConfiguration.collectorHost;
    
    
    [self transition:NRMA_HARVEST_DISCONNECTED];
}
- (void) disconnected
{}
- (void) connected
{}
- (void) disabled
{}

@end
@implementation NRMAHarvesterStateTest
- (void) setUp
{
    [super setUp];
    harvest = [[TestHarvester alloc] init];
}
- (void) tearDown
{
    harvest = nil;
    [super tearDown];

}
- (void) testHarvestStateTransitions
{
    XCTAssertEqual(harvest.currentState, NRMA_HARVEST_UNINITIALIZED, @"");
    
    XCTAssertThrows([harvest transition:NRMA_HARVEST_CONNECTED],@"cannot transition to connected from uninitialized state");
    
    XCTAssertEqual(harvest.currentState, NRMA_HARVEST_UNINITIALIZED, @"expected");
    [harvest transition:NRMA_HARVEST_DISABLED];
    XCTAssertEqual(harvest.currentState, NRMA_HARVEST_DISABLED, @"");
    
    XCTAssertThrows([harvest transition:NRMA_HARVEST_UNINITIALIZED], @"");
}

- (void) testHarvestStateTransitions2
{
    [harvest transition:NRMA_HARVEST_DISCONNECTED];
    XCTAssertEqual(harvest.currentState, NRMA_HARVEST_DISCONNECTED, @"");
    
    [harvest transition:NRMA_HARVEST_DISCONNECTED];
    XCTAssertEqual(harvest.currentState, NRMA_HARVEST_DISCONNECTED, @"");
    
    [harvest transition:NRMA_HARVEST_UNINITIALIZED];
    XCTAssertEqual(harvest.currentState, NRMA_HARVEST_UNINITIALIZED, @"");
    
    [harvest transition:NRMA_HARVEST_DISCONNECTED];
    XCTAssertEqual(harvest.currentState, NRMA_HARVEST_DISCONNECTED, @"");
}

- (void) testHarvestStateTransition3
{
    [harvest transition:NRMA_HARVEST_DISCONNECTED];
    XCTAssertEqual(harvest.currentState, NRMA_HARVEST_DISCONNECTED, @"");
    //transition to connect
    [harvest transition:NRMA_HARVEST_CONNECTED];
    XCTAssertEqual(harvest.currentState, NRMA_HARVEST_CONNECTED, @"");
    
    //connected -> disconnected -> connected
    [harvest transition:NRMA_HARVEST_DISCONNECTED];
    XCTAssertEqual(harvest.currentState, NRMA_HARVEST_DISCONNECTED, @"");
    
    [harvest transition:NRMA_HARVEST_CONNECTED];
    XCTAssertEqual(harvest.currentState, NRMA_HARVEST_CONNECTED, @"");
    
    [harvest transition:NRMA_HARVEST_DISABLED];
    XCTAssertEqual(harvest.currentState, NRMA_HARVEST_DISABLED, @"");
    
    XCTAssertThrows([harvest transition:NRMA_HARVEST_CONNECTED],@"");
 
    XCTAssertEqual(harvest.currentState, NRMA_HARVEST_DISABLED, @"");
}


@end
