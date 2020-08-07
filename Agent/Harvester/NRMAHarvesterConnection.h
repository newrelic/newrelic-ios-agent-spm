//
//  NRMAHarvesterConnection.h
//  NewRelicAgent
//
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAConnectInformation.h"
#import "NRMAHarvestResponse.h"
#import "NRLogger.h"
#import "NRMAJSON.h"
#import "NRMAConnection.h"


#define kCOLLECTOR_CONNECT_URI         @"/mobile/v4/connect"
#define kCOLLECTOR_DATA_URL            @"/mobile/v3/data"
#define kAPPLICATION_TOKEN_HEADER      @"X-App-License-Key"
#define kCONNECT_TIME_HEADER           @"X-NewRelic-Connect-Time"


@interface NRMAHarvesterConnection : NRMAConnection
@property(strong) NSString*             collectorHost;
@property(strong) NSString*             crossProcessID;
@property(assign) long long             serverTimestamp;
@property(strong) NRMAConnectInformation* connectionInformation;
@property(strong) NSURLSession* harvestSession;

- (id) init;
- (NSURLRequest*) createPostWithURI:(NSString*)uri message:(NSString*)message;
- (NRMAHarvestResponse*) send:(NSURLRequest*)post;
- (NRMAHarvestResponse*) sendConnect;
- (NRMAHarvestResponse*) sendData:(NRMAHarvestable*)harvestable;
- (NSURLRequest*) createConnectPost:(NSString*)message;
- (NSURLRequest*) createDataPost:(NSString*)message;
@end
