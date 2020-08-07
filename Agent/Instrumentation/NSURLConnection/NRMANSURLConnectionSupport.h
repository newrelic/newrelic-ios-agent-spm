//
//  NRMANSURLConnectionSupport.h
//  NewRelicAgent
//
//  Created by Jonathan Karon on 10/31/13.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NRMANSURLConnectionDelegateBase;

@interface NRMANSURLConnectionSupport : NSObject

+ (BOOL) instrumentNSURLConnection;
+ (BOOL) deinstrumentNSURLConnection;

@end
