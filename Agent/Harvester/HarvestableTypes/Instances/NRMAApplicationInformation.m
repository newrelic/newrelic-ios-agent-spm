//
//  NRMAApplicationInformation.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/27/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAApplicationInformation.h"

@implementation NRMAApplicationInformation

- (id) init
{
    return [super init];
}

- (id) initWithAppName:(NSString*)appName
            appVersion:(NSString*)appVersion
             bundleId:(NSString *)bundleId
{
    self = [super init];
    if (self) {
        self.appName = appName;
        self.appVersion = appVersion;
        self.bundleId = bundleId;
    }
    return self;
}

- (id) initWithDictionary:(NSDictionary*)dictionary
{
    self = [super init];
    if (self) {
        self.appName = [dictionary objectForKey:kNRMAAppInfoAppName];
        self.appVersion = [dictionary objectForKey:kNRMAAppInfoAppVersion];
        self.bundleId = [dictionary objectForKey:kNRMAAppInfoBundleId];
    }
    return self;
}

- (BOOL) isEqual:(id)object
{
    NRMAApplicationInformation* that = (NRMAApplicationInformation*)object;
    if (![object isKindOfClass:[NRMAApplicationInformation class]]) return NO;
    if (![self.appName isEqualToString:that.appName]) return NO;
    if (![self.appVersion isEqualToString:that.appVersion]) return NO;
    return [self.bundleId isEqualToString:that.bundleId];
}

- (NSUInteger) hash
{
    return [self.appName hash] | [self.appVersion hash] | [self.bundleId  hash];
}

- (id) JSONObject
{
    NSMutableArray* array = [NSMutableArray array];
    [self notEmpty:self.appName];
    [array addObject:self.appName];
    [self notEmpty:self.appVersion];
    [array addObject:self.appVersion];
    [self notEmpty:self.bundleId];
    [array addObject:self.bundleId];
    
    return array;
}

- (NSDictionary*) asDictionary
{
    return @{kNRMAAppInfoAppName: self.appName, kNRMAAppInfoAppVersion:self.appVersion, kNRMAAppInfoBundleId:self.bundleId};
}
@end
