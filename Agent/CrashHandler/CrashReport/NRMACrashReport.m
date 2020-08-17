//
//  NRMACrashReport.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/6/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMACrashReport.h"
#import "NewRelicInternalUtils.h"
@implementation NRMACrashReport


- (instancetype) initWithUUID:(NSString*)uuid
              buildIdentifier:(NSString*)buildIdentifier
                    timestamp:(NSNumber*)timestamp
                     appToken:(NSString*)appToken
                    accountId:(NSNumber*)accountId
                      agentId:(NSNumber*)agentId
                   deviceInfo:(NRMACrashReport_DeviceInfo*)deviceInfo
                      appInfo:(NRMACrashReport_AppInfo*)appInfo
                    exception:(NRMACrashReport_Exception*)exception
                      threads:(NSMutableArray*)threads
                    libraries:(NSMutableArray*)libraries
              activityHistory:(NSArray*)activityHistory
            sessionAttributes:(NSDictionary*)attributes
              AnalyticsEvents:(NSArray*)events
{
    self = [super init];
    if (self) {
        _uuid = uuid;
        _buildIdentifier = buildIdentifier;
        _timestamp = timestamp;
        _appToken = appToken;
        _accountId = accountId;
        _agentId = agentId;
        _deviceInfo = deviceInfo;
        _appInfo = appInfo;
        _exception = exception;
        _threads = threads;
        _libraries =  libraries;
        _activityHistory = activityHistory;
        _events = events;
        _sessionAttributes = attributes;

    }
    return self;
}
- (id) JSONObject
{
    NSArray* dataToken = @[self.accountId?:@0,self.agentId?:@0];

    NSMutableDictionary* jsonDictionary = [[NSMutableDictionary alloc]init];
    jsonDictionary[kNRMA_CR_protocolVersionKey] = self.protocolVersion?:[NSNull null];
    jsonDictionary[kNRMA_CR_platformKey] = self.platform?:[NSNull null];
    jsonDictionary[kNRMA_CR_uuidKey] = self.uuid?:[NSNull null];
    jsonDictionary[kNRMA_CR_buildIdentifierKey] = self.buildIdentifier?:[NSNull null];
    jsonDictionary[kNRMA_CR_timestampKey] = self.timestamp?:[NSNull null];
    jsonDictionary[kNRMA_CR_appTokenKey] = self.appToken?:[NSNull null];
    jsonDictionary[kNRMA_CR_dataToken] = dataToken?:[NSNull null];
    jsonDictionary[kNRMA_CR_deviceInfoKey] = [self.deviceInfo  JSONObject]?:[NSNull null];
    jsonDictionary[kNRMA_CR_appInfoKey] = [self.appInfo JSONObject]?:[NSNull null];
    jsonDictionary[kNRMA_CR_exceptionKey] = [self.exception JSONObject]?:[NSNull null];


    NSArray* threadArray = [self.threads copy];
    NSMutableArray* threadsJson = [[NSMutableArray alloc] init];
    for (NRMACrashReport_Thread* thread in threadArray){
        [threadsJson addObject:[thread JSONObject]?:[NSNull null]];
    }

    jsonDictionary[kNRMA_CR_threadsKey] = threadsJson?:[NSNull null];

    NSArray* libArray = [self.libraries copy];
    NSMutableArray* libJSON = [[NSMutableArray alloc] init];
    for (NRMACrashReport_Library* library in libArray) {
        [libJSON addObject:[library JSONObject]?:[NSNull null]];
    }

    jsonDictionary[kNRMA_CR_librariesKey] = libJSON?:[NSNull null];

    jsonDictionary[kNRMA_CR_activityHistory] = self.activityHistory?:[NSNull null];

    jsonDictionary[kNRMA_CR_userData] = @[];

    jsonDictionary[kNRMA_CR_sessionAttributes] = self.sessionAttributes?:[NSNull null];

    jsonDictionary[kNRMA_CR_analyticsEvents] = self.events?:[NSNull null];

    return  jsonDictionary;
}

- (NSNumber*) protocolVersion
{
         return kNRMACrashProtocolVersion;
}

- (NSString*) platform
{
    return [NewRelicInternalUtils osName];
}

@end
