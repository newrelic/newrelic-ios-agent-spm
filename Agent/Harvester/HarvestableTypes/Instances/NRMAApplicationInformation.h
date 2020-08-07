//
//  NRMAApplicationInformation.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/27/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NRMAHarvestableArray.h"

#define kNRMAAppInfoAppName @"com.newrelic.AppInfo.appName"
#define kNRMAAppInfoAppVersion @"com.newrelic.AppInfo.appVersion"
#define kNRMAAppInfoBundleId @"com.newrelic.AppInfo.bundleId"
@interface NRMAApplicationInformation : NRMAHarvestableArray
@property(strong) NSString* appName;
@property(strong) NSString* appVersion;
@property(strong) NSString* appBuild;
@property(strong) NSString* bundleId;


- (id) initWithAppName:(NSString*)appName
            appVersion:(NSString*)appVersion
             bundleId:(NSString*)bundleId;

- (id) initWithDictionary:(NSDictionary*)dictionary;

- (id) JSONObject;
- (NSDictionary*) asDictionary;
@end
