//
//  NRMACrashReport.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/6/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMACrashReport_AppInfo.h"
#import "NRMACrashReport_DeviceInfo.h"
#import "NRMACrashReport_Exception.h"
#import "NRMACrashReport_Library.h"
#import "NRMACrashReport_Thread.h"
#import "NRMAJSON.h"

#define kNRMACrashProtocolVersion @1.0

#define kNRMA_CR_protocolVersionKey @"protocolVersion"
#define kNRMA_CR_platformKey        @"platform"
#define kNRMA_CR_uuidKey            @"uuid"
#define kNRMA_CR_buildIdentifierKey @"buildId"
#define kNRMA_CR_timestampKey       @"timestamp"
#define kNRMA_CR_appTokenKey        @"appToken"
#define kNRMA_CR_dataToken          @"dataToken"
#define kNRMA_CR_deviceInfoKey      @"deviceInfo"
#define kNRMA_CR_appInfoKey         @"appInfo"
#define kNRMA_CR_exceptionKey       @"exception"
#define kNRMA_CR_threadsKey         @"threads"
#define kNRMA_CR_librariesKey       @"libraries"
#define kNRMA_CR_activityHistory    @"activityHistory"
#define kNRMA_CR_userData           @"userData"
#define kNRMA_CR_sessionAttributes  @"sessionAttributes"
#define kNRMA_CR_analyticsEvents    @"analyticsEvents"

@interface NRMACrashReport : NSObject <NRMAJSONABLE>
@property(strong,readonly) NSNumber* protocolVersion;
@property(strong,readonly) NSString* platform;
@property(strong) NSString* uuid;
@property(strong) NSString* buildIdentifier;
@property(strong) NSNumber* timestamp;
@property(strong) NSString* appToken;
@property(strong) NSNumber* accountId;
@property(strong) NSNumber* agentId;

// deviceInfo
@property(strong) NRMACrashReport_DeviceInfo* deviceInfo;

// App Info
@property(strong) NRMACrashReport_AppInfo* appInfo;

// exception
@property(strong) NRMACrashReport_Exception* exception;

// threads []
@property(strong) NSMutableArray* threads;

// libraries
@property(strong) NSMutableArray* libraries;

// activity traces
@property(strong) NSArray* activityHistory;

// userData

// sessionAttributes
@property(strong) NSDictionary* sessionAttributes;

//AnalyticsEvents
@property(strong) NSArray* events;

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
              AnalyticsEvents:(NSArray*)events;

@end
