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
    [jsonDictionary setObject:self.appName?:[NSNull null] forKey:kNRMA_CR_appNameKey];
    [jsonDictionary setObject:self.appVersion?:[NSNull null] forKey:kNRMA_CR_appVersionKey];
    [jsonDictionary setObject:self.appBuild?:[NSNull null]
                       forKey:kNRMA_CR_appBuildKey];
    [jsonDictionary setObject:self.bundleId?:[NSNull null] forKey:kNRMA_CR_bundleIdKey];
    [jsonDictionary setObject:self.processPath?:[NSNull null] forKey:kNRMA_CR_processPath];
    [jsonDictionary setObject:self.processName?:[NSNull null] forKey:kNRMA_CR_processName];
    [jsonDictionary setObject:self.processId?:[NSNull null] forKey:kNRMA_CR_processId];
    [jsonDictionary setObject:self.parentProcess?:[NSNull null] forKey:kNRMA_CR_parentProcess];
    [jsonDictionary setObject:self.parentProcessId?:[NSNull null] forKey:kNRMA_CR_parentProcessId];
    return jsonDictionary;
}
@end
