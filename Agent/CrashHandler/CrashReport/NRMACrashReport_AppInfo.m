//
//  NRMACrashReport_AppInfo.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/6/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMACrashReport_AppInfo.h"

@implementation NRMACrashReport_AppInfo
- (instancetype) initWithAppName:(NSString*)appName
                      appVersion:(NSString*)appVersion
                        appBuild:(NSString*)appBuild
                        bundleId:(NSString*)bundleId
                     processPath:(NSString*)processPath
                     processName:(NSString*)processName
                       processId:(NSNumber*)processId
                   parentProcess:(NSString*)parentProcess
                 parentProcessId:(NSNumber*)parentProcessId
{
    self = [super init];
    if (self) {
        _appName = appName;
        _appVersion = appVersion;
        _appBuild   = appBuild;
        _bundleId = bundleId;
        _processPath = processPath;
        _processName = processName;
        _processId = processId;
        _parentProcess = parentProcess;
        _parentProcessId = parentProcessId;
    }
    return self;
}

- (id) JSONObject
{
    /*
     @property(strong) NSString* appName;
     @property(strong) NSString* appVersion;
     @property(strong) NSString* bundleId;
     @property(strong) NSString* processPath;
     @property(strong) NSString* processName;
     @property(strong) NSNumber* processId;
     @property(strong) NSString* parentProcess;
     @property(strong) NSNumber* parentProcessId;
     */
    NSMutableDictionary* jsonDictionary = [[NSMutableDictionary alloc] init];
    jsonDictionary[kNRMA_CR_appNameKey] = self.appName ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_appVersionKey] = self.appVersion ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_appBuildKey] = self.appBuild ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_bundleIdKey] = self.bundleId ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_processPath] = self.processPath ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_processName] = self.processName ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_processId] = self.processId ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_parentProcess] = self.parentProcess ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_parentProcessId] = self.parentProcessId ?: (id) [NSNull null];
    return jsonDictionary;
}
@end
