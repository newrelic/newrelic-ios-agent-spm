//
//  NRMAHavester.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/27/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAHarvesterConnection.h"
#import "NRMAHarvesterConfiguration.h"
#import "NRMAAgentConfiguration.h"
#import "NRLogger.h"
#import "NRMAJSON.h"
#import "NRMAHarvestData.h"
#import "NRMAHarvestAware.h"


#ifdef __cplusplus
extern "C" {
#endif

#define kNRMAIllegalStateException @"IllegalStateException"

#define kNRMAConnectionInformationKey @"com.newrelic.connectionInformation"
#define kNRMAHarvesterConfigurationStoreKey @"com.newrelic.harvesterConfiguration"
#define kNRMAApplicationIdentifierKey @"com.newrelic.applicationIdentifier"

typedef enum {
    NRMA_HARVEST_UNINITIALIZED = 1,
    NRMA_HARVEST_DISCONNECTED,
    NRMA_HARVEST_CONNECTED,
    NRMA_HARVEST_DISABLED
}NRMAHarvesterState;

@protocol NRMAHarvesterProtocol <NSObject>
//used to update the harvest data;
- (NRMAHarvestData*) harvestData;

@end
@interface NRMAHarvester : NSObject <NRMAHarvesterProtocol>
{
    BOOL stateDidChange;
    NRMAHarvesterConnection* connection;
    NRMAHarvesterConfiguration* configuration;
    NRMAAgentConfiguration* _agentConfiguration;
    

}

@property(readonly) NRMAHarvesterState currentState;
@property(nonatomic,strong) NRMAHarvestData* harvestData;
- (void) execute;
- (void) setAgentConfiguration:(NRMAAgentConfiguration*)agentConfiguration;
- (void) configureHarvester:(NRMAHarvesterConfiguration*)harvestConfiguration;
- (void) saveHarvesterConfiguration:(NRMAHarvesterConfiguration*)harvestConfiguration;
- (NRMAHarvesterConfiguration*) fetchHarvestConfiguration;
- (void) transition:(NRMAHarvesterState)state;
- (NSString*) crossProcessID;
- (NRMAHarvesterConfiguration*) harvesterConfiguration;

////harvest aware
- (NSArray*) getHarvestAwareList;
- (void) addHarvestAwareObject:(id<NRMAHarvestAware>)harvestAware;
- (void) removeHarvestAwareObject:(id<NRMAHarvestAware>)harvestAware;
- (void) fireOnHarvestStart;
- (void) stop;
@end

#ifdef __cplusplus
}
#endif // extern "C" {
