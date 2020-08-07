//
//  NRMAConnectInformation.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/27/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAConnectInformation.h"

@implementation NRMAConnectInformation

- (id) JSONObject
{
    [self notNull:self.applicationInformation];
    [self notNull:self.deviceInformation];
    
    return @[[self.applicationInformation JSONObject], [self.deviceInformation JSONObject]];
}

- (NSString *) toApplicationIdentifier
{
    NSArray* parts = @[self.applicationInformation.appName,
                       self.applicationInformation.appVersion,
                       self.applicationInformation.bundleId,
                       self.deviceInformation.osName,
                       self.deviceInformation.osVersion,
                       self.deviceInformation.manufacturer,
                       self.deviceInformation.model,
                       self.deviceInformation.agentName,
                       self.deviceInformation.agentVersion,
                       self.deviceInformation.deviceId];
    return [parts componentsJoinedByString:@","];
}

- (NSDictionary*) asDictionary
{
    return @{kNRMAConnectionInfoApplicationInfo: [self.applicationInformation asDictionary],
             kNRMAConnectionInfoDeviceInfo:[self.deviceInformation asDictionary]};
}

- (id) initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.applicationInformation = [[NRMAApplicationInformation alloc] initWithDictionary:[dictionary objectForKey:kNRMAConnectionInfoApplicationInfo]];
        self.deviceInformation = [[NRMADeviceInformation alloc] initWithDictionary:[dictionary objectForKey:kNRMAConnectionInfoDeviceInfo]];
    }
    return self;
}


- (NSUInteger) hash {
    return [self.applicationInformation hash] | [self.deviceInformation hash];
}
- (BOOL) isEqual:(id)object
{
    NRMAConnectInformation* that = (NRMAConnectInformation*)object;
    if (![object isKindOfClass:[NRMAConnectInformation class]]) return NO;
    if (![self.applicationInformation isEqual:that.applicationInformation]) return NO;
    if (![self.deviceInformation isEqual:that.deviceInformation]) return NO;
    return YES;
}

@end
