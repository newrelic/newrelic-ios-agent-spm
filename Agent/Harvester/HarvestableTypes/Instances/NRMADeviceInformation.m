//
//  NRMADeviceInformation.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/27/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMADeviceInformation.h"
#import "NewRelicAgentInternal.h"
#import "NewRelicInternalUtils.h"

#include <Analytics/Constants.hpp>

@implementation NRMADeviceInformation
@synthesize misc = _misc;

- (id) JSONObject
{
    [self notEmpty:self.osName];
    [self notEmpty:self.osVersion];
    [self notEmpty:self.manufacturer];
    [self notEmpty:self.model];
    [self notEmpty:self.agentName];
    [self notEmpty:self.agentVersion];
    [self notEmpty:self.deviceId];
    

    NSMutableArray* array = [NSMutableArray arrayWithArray:@[self.osName,
                             self.osVersion,
                             self.model,
                             self.agentName,
                             self.agentVersion,
                             self.deviceId,
                             [self optional:self.countryCode],
                             [self optional:self.regionCode],
                             self.manufacturer,
                            self.misc.count?self.misc:[NSDictionary dictionary]]];


    return array;
}


- (NSMutableDictionary*) misc {
    NSMutableDictionary* temp = [NSMutableDictionary dictionaryWithDictionary:_misc];
    temp[@(__kNRMA_RA_platform)] = [NewRelicInternalUtils stringFromNRMAApplicationPlatform:self.platform];
    temp[@(__kNRMA_RA_platformVersion)] =  self.platformVersion?:self.agentVersion;
    return temp;
}

- (void) setMisc:(NSMutableDictionary*) misc {
    _misc = misc;
}

- (BOOL) isEqual:(id)object
{
    NRMADeviceInformation* that = (NRMADeviceInformation*)object;
    if (![object isKindOfClass:[NRMADeviceInformation class]]) return NO;
    if (![that.osName isEqualToString:self.osName]) return NO;
    if (![that.osVersion isEqualToString:self.osVersion]) return NO;
    if (![that.manufacturer isEqualToString:self.manufacturer]) return NO;
    if (![that.model isEqualToString:self.model]) return NO;
    if (![that.agentName isEqualToString:self.agentName]) return NO;
    if (![that.agentVersion isEqualToString:self.agentVersion]) return NO;
    return [that.deviceId isEqualToString:self.deviceId];
}

- (NSUInteger) hash
{
    return [self.osName hash] |
            [self.osVersion hash] |
            [self.manufacturer hash] |
            [self.model hash] |
            [self.agentName hash] |
            [self.agentVersion hash] |
    [self.deviceId hash];
}

- (NSDictionary*) asDictionary
{
    return @{kNRMADeviceInfoOSName:self.osName?:@"",
             kNRMADeviceInfoOSVersion:self.osVersion?:@"",
             kNRMADeviceInfoManufacturer:self.manufacturer?:@"",
             kNRMADeviceInfoModel:self.model?:@"",
             kNRMADeviceInfoAgentName:self.agentName?:@"",
             kNRMADeviceInfoAgentVersion:self.agentVersion?:@"",
             kNRMADeviceInfoDeviceId:self.deviceId?:@"",
             kNRMADeviceInfoCountryCode:self.countryCode?:@"",
             kNRMADeviceInfoRegionCode:self.regionCode?:@"",
             kNRMADeviceInfoMisc:self.misc?:@{}};
}

- (id) initWithDictionary:(NSDictionary*)dictionary
{
    self = [super init];
    if (self) {
        self.osName = [dictionary objectForKey:kNRMADeviceInfoOSName];
        self.osVersion = [dictionary objectForKey:kNRMADeviceInfoOSVersion];
        self.manufacturer = [dictionary objectForKey:kNRMADeviceInfoManufacturer];
        self.model = [dictionary objectForKey:kNRMADeviceInfoModel];
        self.agentName = [dictionary objectForKey:kNRMADeviceInfoAgentName];
        self.agentVersion = [dictionary objectForKey:kNRMADeviceInfoAgentVersion];
        self.deviceId = [dictionary objectForKey:kNRMADeviceInfoDeviceId];
        self.countryCode = [dictionary objectForKey:kNRMADeviceInfoCountryCode];
        self.regionCode = [dictionary objectForKey:kNRMADeviceInfoRegionCode];
        self.misc = [dictionary objectForKey:kNRMADeviceInfoMisc];
    }
    return self;
}
@end
