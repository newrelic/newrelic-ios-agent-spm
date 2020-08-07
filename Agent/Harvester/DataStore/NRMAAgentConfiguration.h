//
//  NRMAAgentConfiguration.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/29/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAConnectInformation.h"
#import <Foundation/Foundation.h>

@class NRMAAppToken;


#define kNRMA_DEFAULT_COLLECTOR_HOST         @"mobile-collector.newrelic.com"
#define kNRMA_DEFAULT_CRASH_COLLECTOR_HOST   @"mobile-crash.newrelic.com"
#define kNRMA_REGION_SPECIFIC_COLLECTOR_HOST @"mobile-collector.%@.nr-data.net"
#define kNRMA_REGION_SPECIFIC_CRASH_HOST     @"mobile-crash.%@.nr-data.net"

@interface NRMAAgentConfiguration : NSObject

@property(readonly,strong) NSString* collectorHost;
@property(readonly,strong) NSString* crashCollectorHost;
@property(readonly,strong) NRMAAppToken* applicationToken;
@property(atomic,strong) NSString* sessionIdentifier;
@property(nonatomic,readonly) BOOL      useSSL;
@property(atomic,assign) NRMAApplicationPlatform platform;
- (id) initWithAppToken:(NRMAAppToken*)token collectorAddress:(NSString*)collectorAddress crashAddress:(NSString*)crashAddress;

+ (NRMAConnectInformation*) connectionInformation;
+ (void)setApplicationVersion:(NSString *)versionString;
+ (void)setApplicationBuild:(NSString *)buildString;
+ (void) setPlatform:(NRMAApplicationPlatform)platform;
+ (void) setPlatformVersion:(NSString*)platformVersion;
@end
