//
//  NRMACrashReport_DeviceInfo.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/6/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAJSON.h"


#define kNRMA_CR_memoryUsageKey     @"memoryUsage"
#define kNRMA_CR_orientationKey     @"orientation"
#define kNRMA_CR_networkStatusKey   @"networkStatus"
#define kNRMA_CR_diskUsageKey       @"diskAvailable"
#define kNRMA_CR_osVersionKey       @"osVersion"
#define KNRMA_CR_deviceNameKey      @"deviceName"
#define kNRMA_CR_osBuildKey         @"osBuild"  
#define kNRMA_CR_architectureKey    @"architecture"
#define kNRMA_CR_modelNumberKey     @"modelNumber"
#define kNRMA_CR_deviceUuid         @"deviceUuid"

@interface NRMACrashReport_DeviceInfo : NSObject <NRMAJSONABLE>
@property(strong) NSNumber* memoryUsage; //<long long>
@property(strong) NSNumber* orientation; //<int>
@property(strong) NSString* networkStatus;
@property(strong) NSArray* diskUsage; //[<long long>,...];
@property(strong) NSString* osVersion;
@property(strong) NSString* deviceName;
@property(strong) NSString* osBuild;
@property(strong) NSString* architecture;
@property(strong) NSString* modelNumber;
@property(strong) NSString* deviceUuid;

- (instancetype) initWithMemoryUsage:(NSNumber*)memoryUsage
                         orientation:(NSNumber*)orientation
                       networkStatus:(NSString*)networkStatus
                           diskUsage:(NSArray*)diskUsage
                           osVersion:(NSString*)osVersion
                          deviceName:(NSString*)deviceName
                             osBuild:(NSString*)osBuild
                        architecture:(NSString*)architecture
                         modelNumber:(NSString*)modelNumber
                          deviceUuid:(NSString*)deviceUuid;

- (id) JSONObject;
@end

