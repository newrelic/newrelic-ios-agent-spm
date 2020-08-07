//
//  NRMACrashReport_DeviceInfo.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/6/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMACrashReport_DeviceInfo.h"

@implementation NRMACrashReport_DeviceInfo


- (instancetype) initWithMemoryUsage:(NSNumber*)memoryUsage
                         orientation:(NSNumber*)orientation
                       networkStatus:(NSString*)networkStatus
                           diskUsage:(NSArray*)diskUsage
                           osVersion:(NSString*)osVersion
                          deviceName:(NSString*)deviceName
                             osBuild:(NSString*)osBuild
                        architecture:(NSString*)architecture
                         modelNumber:(NSString*)modelNumber
                          deviceUuid:(NSString*)deviceUuid
{
    self = [super init];
    if (self) {
        _memoryUsage = memoryUsage?:@-1;
        _orientation = orientation?:@1;
        _networkStatus = networkStatus?:@"unknown";
        _diskUsage = diskUsage;
        _osVersion = osVersion;
        _deviceName = deviceName;
        _osBuild = osBuild;
        _architecture = architecture;
        _modelNumber = modelNumber;
        _deviceUuid = deviceUuid;
    }
    return self;
}

- (id) JSONObject
{
    /*
     @property(strong) NSNumber* memoryUsage; //<long long>
     @property(strong) NSNumber* orientation; //<int>
     @property(strong) NSString* networkStatus;
     @property(strong) NSArray* diskUsage; //[<long long>,...];
     @property(strong) NSString* osVersion;
     @property(strong) NSString* deviceName;
     @property(strong) NSString* osBuild;
     @property(strong) NSString* architecture;
     @property(strong) NSString* modelNumber;
     */
    NSMutableDictionary* jsonDictionary = [[NSMutableDictionary alloc] init];
    [jsonDictionary setObject:self.memoryUsage?:[NSNull null] forKey:kNRMA_CR_memoryUsageKey];
    [jsonDictionary setObject:self.orientation?:[NSNull null] forKey:kNRMA_CR_orientationKey];
    [jsonDictionary setObject:self.networkStatus?:[NSNull null] forKey:kNRMA_CR_networkStatusKey];
    [jsonDictionary setObject:self.diskUsage?:[NSNull null] forKey:kNRMA_CR_diskUsageKey];
    [jsonDictionary setObject:self.osVersion?:[NSNull null] forKey:kNRMA_CR_osVersionKey];
    [jsonDictionary setObject:self.deviceName?:[NSNull null] forKey:KNRMA_CR_deviceNameKey];
    [jsonDictionary setObject:self.osBuild?:[NSNull null] forKey:kNRMA_CR_osBuildKey];
    [jsonDictionary setObject:self.architecture?:[NSNull null] forKey:kNRMA_CR_architectureKey];
    [jsonDictionary setObject:self.modelNumber?:[NSNull null] forKey:kNRMA_CR_modelNumberKey];
    [jsonDictionary setObject:self.deviceUuid?:[NSNull null] forKey:kNRMA_CR_deviceUuid];
    return jsonDictionary;
}
@end
