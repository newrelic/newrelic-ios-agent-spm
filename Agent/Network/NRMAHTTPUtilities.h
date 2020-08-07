//
//  NRMANetworkUtilites.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/28/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAPayloadContainer.h"

#define NEW_RELIC_DISTRIBUTED_TRACING_HEADER_KEY               @"newrelic"

@interface NRMAHTTPUtilities : NSObject
+ (NSMutableURLRequest*) addCrossProcessIdentifier:(NSURLRequest*)request;
+ (NSMutableURLRequest*) makeMutable:(NSURLRequest*)request;
+ (NSMutableURLRequest*) addConnectivityHeaderAndPayload:(NSURLRequest*)request;
+ (NRMAPayloadContainer*) addConnectivityHeader:(NSMutableURLRequest*)request;
+ (void) attachPayload:(NRMAPayloadContainer*)payload to:(id)object;
@end
