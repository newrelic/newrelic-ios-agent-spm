//
//  NRMACrashReport_AppInfo.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/6/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAJSON.h"
#define kNRMA_CR_appNameKey         @"appName"
#define kNRMA_CR_appVersionKey      @"appVersion"
#define kNRMA_CR_appBuildKey        @"appBuild"
#define kNRMA_CR_bundleIdKey        @"bundleId"
#define kNRMA_CR_processPath        @"processPath"
#define kNRMA_CR_processName        @"processName"
#define kNRMA_CR_processId          @"processId"
#define kNRMA_CR_parentProcess      @"parentProcess"
#define kNRMA_CR_parentProcessId    @"parentProcessId"

@interface NRMACrashReport_AppInfo : NSObject <NRMAJSONABLE>
@property(strong) NSString* appName;
@property(strong) NSString* appVersion;
@property(strong) NSString* appBuild;
@property(strong) NSString* bundleId;
@property(strong) NSString* processPath;
@property(strong) NSString* processName;
@property(strong) NSNumber* processId;
@property(strong) NSString* parentProcess;
@property(strong) NSNumber* parentProcessId;

- (instancetype) initWithAppName:(NSString*)appName
                      appVersion:(NSString*)appVersion
                        appBuild:(NSString*)appBuild
                        bundleId:(NSString*)bundleId
                     processPath:(NSString*)processPath
                     processName:(NSString*)processName
                       processId:(NSNumber*)processId
                   parentProcess:(NSString*)parentProcess
                 parentProcessId:(NSNumber*)parentProcessId;

@end
