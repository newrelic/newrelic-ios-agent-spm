//
//  NRHarvest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/3/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestController.h"
#import "NRMAExceptionHandler.h"
#import "NewRelicInternalUtils.h"

#ifdef __cplusplus
extern "C" {
#endif
static NRMAHarvestController* __harvestController;
static NRMAAgentConfiguration* __agentConfiguration;

static NSString* NRMAHarvestConfigAccessorLock = @"LOCK";
static NSString* NRMAHarvestControllerInitializationLock = @"LOCK";
static NSString* NRMAHarvestControllerAccessorLock = @"LOCK";

@interface NRMAHarvestController()
@property(strong, atomic) NSMutableArray* harvestAwareList;
@property(strong, atomic) NRMAHarvester* harvester;
@property(strong, atomic) NRMAHarvestTimer* harvestTimer;
@end

@implementation NRMAHarvestController

- (instancetype) init
{
    self = [super init];
    if (self) {
        self.harvestAwareList = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) dealloc
{
    self.harvestAwareList = nil;
    self.harvester = nil;
    [self.harvestTimer stop];
    self.harvestTimer = nil;
}

- (void) deinitialize
{
    [self.harvestTimer stop];
    self.harvestTimer = nil;
}

+ (NRMAHarvestController*) harvestController
{
    @synchronized(NRMAHarvestControllerAccessorLock) {
        return __harvestController;
    }
}

+ (void) setHarvestController:(NRMAHarvestController*)harvestController
{
    @synchronized(NRMAHarvestControllerAccessorLock) {
        __harvestController = harvestController;
    }
}

+ (NRMAAgentConfiguration*) agentConfiguration
{
    @synchronized(NRMAHarvestConfigAccessorLock) {
        return __agentConfiguration;
    }
}

+ (void) setAgentConfiguration:(NRMAAgentConfiguration*)agentConfig
{
    @synchronized(NRMAHarvestConfigAccessorLock) {
        __agentConfiguration = agentConfig;
    }
}

+ (void) setPeriod:(long long)period
{
    [[NRMAHarvestController harvestController] harvestTimer].period = period;
}

+ (void) deinitialize
{
    [[NRMAHarvestController harvestController] deinitialize];
    [self setHarvestController:nil];
    [self setAgentConfiguration:nil];
}

+ (void) initialize:(NRMAAgentConfiguration*)configuration
{
    @synchronized(NRMAHarvestControllerInitializationLock) {
        [self setHarvestController:[[NRMAHarvestController alloc] init]];
        NRMAHarvestController* controller = [NRMAHarvestController harvestController];
        [self setAgentConfiguration:configuration];
        @synchronized(controller) {
            [controller createHarvester];
            [[controller harvester] setAgentConfiguration:configuration];
            [[controller harvester] configureHarvester:[NRMAHarvesterConfiguration defaultHarvesterConfiguration]];
        }
    }
}


+ (void) recovery
{
    [NRMAHarvestController stop];

    NSArray* harvestAwareList = [self harvestController].harvestAwareList;
    NRMAAgentConfiguration* config = [self agentConfiguration];
    [NRMAHarvestController deinitialize];

    [NRMAHarvestController initialize:config];
    for (id<NRMAHarvestAware> obj in harvestAwareList) {
        [[self harvestController] addHarvestAwareObject:obj];
    }

    [NRMAHarvestController start];
}


+ (void) start
{
    static dispatch_queue_t harvestQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        harvestQueue = dispatch_queue_create("harvesterQueue", NULL);
    });

    dispatch_async(harvestQueue, ^{
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
        @try {
#endif
            NRMAHarvestController* controller = [NRMAHarvestController harvestController];
            @synchronized(controller) {
                [[controller harvestTimer] start];
                if ([[controller harvester] currentState] == NRMA_HARVEST_UNINITIALIZED) {
                    [[controller harvester] execute];
                }
                if ([[controller harvester] currentState] == NRMA_HARVEST_DISCONNECTED) {
                    [[controller harvester] execute];
                }
            }
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
        } @catch (NSException* exception) {
            [NRMAExceptionHandler logException:exception
                                         class:NSStringFromClass([self class])
                                      selector:NSStringFromSelector(_cmd)];

            //attempt to recover
            [NRMAHarvestController recovery];
        }
#endif
    });
}

+ (void) stop
{
    @synchronized(NRMAHarvestControllerInitializationLock) {
        NRLOG_VERBOSE(@"Harvester timer stopped");
        [NRMAHarvestController deinitialize];
    }
}

- (void) addHarvestAwareObject:(id<NRMAHarvestAware>)harvestAware
{
    if (self.harvester == nil) {
        @synchronized(self.harvestAwareList) {
            [self.harvestAwareList addObject:harvestAware];
        }
    } else {
        [self.harvester addHarvestAwareObject:harvestAware];
    }
}

- (void) removeHarvestAwareObject:(id<NRMAHarvestAware>)harvestAware
{
    if (self.harvester == nil) {
        @synchronized(self.harvestAwareList) {
            [self.harvestAwareList removeObject:harvestAware];
        }
    } else {
        [self.harvester removeHarvestAwareObject:harvestAware];
    }
}

- (void) createHarvester
{
    self.harvester = [[NRMAHarvester alloc] init];
    @synchronized(self.harvestAwareList) {
        for (id<NRMAHarvestAware> aware in self.harvestAwareList) {
            [self addHarvestAwareObject:aware];
        }
    }
    self.harvestTimer = [[NRMAHarvestTimer alloc] initWithHarvester:self.harvester];
}

+ (NRMAHarvesterConfiguration*) configuration
{
    return [[[NRMAHarvestController harvestController] harvester] harvesterConfiguration];
}

+ (NRMAHarvestData*) harvestData
{
    return [[[NRMAHarvestController harvestController] harvester] harvestData];
}

+ (BOOL) shouldCollectTraces
{
    NRMAHarvestData* harvestData = [[[NRMAHarvestController harvestController] harvester] harvestData];
    NRMAHarvesterConfiguration* configuration = [NRMAHarvestController configuration];

    if (harvestData == nil || configuration == nil)
        return YES;

    // todo: use fine grained AT capture rules later.
    return harvestData.activityTraces.count < configuration.at_capture.maxTotalTraceCount;
}

+ (BOOL) shouldNotCollectTraces
{
    BOOL shouldNotCollect = YES;
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif
        shouldNotCollect = ![self shouldCollectTraces];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                     class:NSStringFromClass([self class])
                                  selector:NSStringFromSelector(_cmd)];
    }
#endif

    return shouldNotCollect;
}


#pragma mark - harvest aware interface

+ (void) addHarvestListener:(id<NRMAHarvestAware>)obj
{
    [[NRMAHarvestController harvestController] addHarvestAwareObject:obj];
}

+ (void) removeHarvestListener:(id<NRMAHarvestAware>)obj
{
    [[NRMAHarvestController harvestController] removeHarvestAwareObject:obj];
}

#pragma mark - private
//private method for testing

+ (BOOL) harvestNow
{ //MAY BLOCK
    if ([[NRMAHarvestController harvestController] harvester].currentState == NRMA_HARVEST_CONNECTED) {
        [[[NRMAHarvestController harvestController] harvester] execute];
        return YES;
    }
    return NO;
}

#pragma  mark - Harvest Data Interface

+ (void) addHarvestableHTTPTransaction:(NRMAHarvestableHTTPTransaction*)transaction
{
    NRMAHarvestData* harvestData = [[self class] harvestData];
    @synchronized(harvestData) {
        [harvestData.httpTransactions add:transaction];
    }
}

+ (void) addHarvestableHTTPError:(NRMAHarvestableHTTPError*)error
{
    NRMAHarvestData* harvestData = [[self class] harvestData];
    @synchronized(harvestData) {
        [harvestData.httpErrors addHTTPError:error];
    }
}

+ (void) addNamedValue:(NRMANamedValueMeasurement*)measurement
{

    NRMAHarvestData* harvestData = [[self class] harvestData];

    NRMANamedValueMeasurement* namedValue = (NRMANamedValueMeasurement*)measurement;

    NSRange exclusiveRange = [measurement.name rangeOfString:@"/ExclusiveTime"
                                                     options:NSBackwardsSearch];
    if (exclusiveRange.location != NSNotFound && measurement.name.length == exclusiveRange.length + exclusiveRange.location) {
        NSString* name = [measurement.name substringWithRange:NSMakeRange(0, exclusiveRange.location)];
        @synchronized(harvestData) {
            [harvestData.metrics addExclusiveTime:namedValue.value
                                        forMetric:name
                                        withScope:namedValue.scope];
        }
    } else {
        @synchronized(harvestData) {
            [harvestData.metrics addValue:namedValue.value
                                forMetric:namedValue.name
                                withScope:namedValue.scope];
        }
    }

}

+ (void) addHarvestableAnalytics:(NRMAHarvestableAnalytics*)analytics
{
    NRMAHarvestData* harvestData = [[self class] harvestData];
    @synchronized(harvestData) {
        [harvestData.analyticsEvents addEvents:analytics.events];
        harvestData.analyticsAttributes = analytics.sessionAttributes;
    }
}

+ (void) addHarvestableActivity:(NRMAHarvestableActivity*)activity
{
    NRMAHarvestData* harvestData = [[self class] harvestData];
    @synchronized(harvestData) {
        [harvestData.activityTraces addActivityTraces:activity];
    }
}
@end

#ifdef __cplusplus
}
#endif
