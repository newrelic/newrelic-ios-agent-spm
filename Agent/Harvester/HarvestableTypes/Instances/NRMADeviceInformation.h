//
//  NRMADeviceInformation.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/27/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestableArray.h"
#import "NRConstants.h"


#define kNRMADeviceInfoOSName @"com.newrelic.deviceinfo.osname"
#define kNRMADeviceInfoOSVersion @"com.newrelic.deviceinfo.osversion"
#define kNRMADeviceInfoModel @"com.newrelic.deviceinfo.model"
#define kNRMADeviceInfoAgentName @"com.newrelic.deviceinfo.agentName"
#define kNRMADeviceInfoAgentVersion @"com.newrelic.deviceinfo.agentVersion"
#define kNRMADeviceInfoDeviceId @"com.newrelic.deviceinfo.deviceid"
#define kNRMADeviceInfoCountryCode @"com.newrelic.deviceinfo.countryCode"
#define kNRMADeviceInfoRegionCode @"com.newrelic.deviceinfo.regioncode"
#define kNRMADeviceInfoManufacturer @"com.newrelic.deviceinfo.manufacturer"
#define kNRMADeviceInfoMisc @"com.newrelic.deviceinfo.misc"

@interface NRMADeviceInformation : NRMAHarvestableArray
@property(strong) NSString* osName;
@property(strong) NSString* osVersion;
@property(strong) NSString* model;
@property(strong) NSString* agentName;
@property(strong) NSString* agentVersion;
@property(strong) NSString* deviceId;
@property(strong) NSString* countryCode;
@property(strong) NSString* regionCode;
@property(strong) NSString* manufacturer;
@property(assign) NRMAApplicationPlatform platform;
@property(assign) NSString* platformVersion;
@property(strong) NSMutableDictionary* misc;

- (id) JSONObject;
- (id) initWithDictionary:(NSDictionary*)dictionary;
- (NSDictionary*) asDictionary;

@end
