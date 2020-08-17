//
//  NRMAHarvesterTest.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/29/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAHarvester.h"
#import "NRAgentTestBase.h"

@interface NRMAHarvestAwareHelper :NSObject <NRMAHarvestAware>
@property(assign,atomic) BOOL harvestedStart;
@property(assign,atomic) BOOL harvestedStop;
@property(assign,atomic) BOOL harvestedBefore;
@property(assign,atomic) BOOL harvested;
@property(assign,atomic) BOOL harvestedError;
@property(assign,atomic) BOOL harvestedComplete;
@end


@interface NRMAHarvesterTest : NRMAAgentTestBase
{
    NRMAAgentConfiguration* agentConfig;
    NRMAHarvester* harvester;
    NRMAHarvestAwareHelper* harvestAwareHelper;
}


@end
