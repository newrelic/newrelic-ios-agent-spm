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
    jsonDictionary[kNRMA_CR_memoryUsageKey] = self.memoryUsage ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_orientationKey] = self.orientation ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_networkStatusKey] = self.networkStatus ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_diskUsageKey] = self.diskUsage ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_osVersionKey] = self.osVersion ?: (id) [NSNull null];
    jsonDictionary[KNRMA_CR_deviceNameKey] = self.deviceName ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_osBuildKey] = self.osBuild ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_architectureKey] = self.architecture ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_modelNumberKey] = self.modelNumber ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_deviceUuid] = self.deviceUuid ?: (id) [NSNull null];
    return jsonDictionary;
}
@end
