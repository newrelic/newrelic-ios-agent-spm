//
//  NRMAKeyAttributes.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/14/17.
//  Copyright © 2017 New Relic. All rights reserved.
//

#import "NRMAKeyAttributes.h"
#import "NewRelicInternalUtils.h"
#import "NRMAAgentConfiguration.h"
#import "NewRelicAgentInternal.h"
#import "NRMADataToken.h"

#define UUID_KEY    @"uuid"
#define APP_VERSION_KEY @"appVersion"
#define APP_NAME_KEY    @"appName"

@implementation NRMAKeyAttributes
+ (NSDictionary*) keyAttributes {

    NSMutableDictionary* attributes = [NSMutableDictionary new];

    NRMAConnectInformation* connInfo = [NRMAAgentConfiguration connectionInformation];
    NSString* appName = connInfo.applicationInformation.appName;
    NSString* appVersion = connInfo.applicationInformation.appVersion;
    NSString* uuid = connInfo.deviceInformation.deviceId;

    [attributes setValue:appName forKey:APP_NAME_KEY];
    [attributes setValue:appVersion forKey:APP_VERSION_KEY];
    [attributes setValue:uuid forKey:UUID_KEY];

   return attributes;
}
@end
