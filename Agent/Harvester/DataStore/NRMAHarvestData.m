//
//  NRMAHarvestData.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/4/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestData.h"
#import "NRMAHarvestController.h"
@implementation NRMAHarvestData

- (id) init
{
    self = [super init];
    if (self) {
        self.dataToken = [[NRMADataToken alloc] init];

        self.deviceInformation = [NRMAAgentConfiguration connectionInformation].deviceInformation;
        
        self.httpTransactions = [[NRMAHTTPTransactions alloc] init];
        [NRMAHarvestController addHarvestListener:self.httpTransactions];
        
        self.httpErrors = [[NRMAHarvestableHTTPErrors alloc] init];
        [NRMAHarvestController addHarvestListener:self.httpErrors];
        
        self.metrics = [[NRMAMetricSet alloc] init];
        [NRMAHarvestController addHarvestListener:self.metrics];
        
        self.activityTraces   = [[NRMAActivityTraces alloc] init];
        [NRMAHarvestController addHarvestListener:self.activityTraces];

        self.analyticsAttributes = [NSDictionary new];

        self.analyticsEvents = [[NRMAAnalyticsEvents alloc] init];
        [NRMAHarvestController addHarvestListener:self.analyticsEvents];

    }
    return self;
}

- (id) JSONObject
{
    NSMutableArray* jsonArray = [[NSMutableArray alloc] init];
    [jsonArray addObject:[self.dataToken JSONObject]];
    [jsonArray addObject:[self.deviceInformation JSONObject]];
    [jsonArray addObject:[NSNumber numberWithLongLong:self.harvestTimeDelta]];
    [jsonArray addObject:[self.httpTransactions JSONObject]];
    [jsonArray addObject:[self.metrics JSONObject]];
    [jsonArray addObject:[self.httpErrors JSONObject]];
    [jsonArray addObject:[self.activityTraces JSONObject]];
    [jsonArray addObject:@[]]; //agent health 
    [jsonArray addObject:self.analyticsAttributes];
    [jsonArray addObject:[self.analyticsEvents JSONObject]];
    return jsonArray;
}

- (void) clear
{
    [self.httpErrors clear];
    [self.httpTransactions clear];
    [self.metrics reset];
    [self.activityTraces clear];
    //todo: make custom objects for these thingies
    self.analyticsAttributes = @{};
    [self.analyticsEvents clear];
}


- (void) addMetrics:(NRMAMetricSet*)objects
{
    [self.metrics addMetrics:objects];
}

- (void) dealloc {
    [NRMAHarvestController removeHarvestListener:self.metrics];
    [NRMAHarvestController removeHarvestListener:self.httpErrors];
    [NRMAHarvestController removeHarvestListener:self.httpTransactions];
    [NRMAHarvestController removeHarvestListener:self.activityTraces];
    [NRMAHarvestController removeHarvestListener:self.analyticsEvents];
}

@end
