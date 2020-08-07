//
//  NRMACrashReport_Exception.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/6/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMACrashReport_Exception.h"

@implementation NRMACrashReport_Exception

- (instancetype) initWithName:(NSString*)name
                        cause:(NSString*)cause
                   signalInfo:(NRMACrashReport_SignalInfo*)signalInfo
{
    self = [super init];
    if (self) {
        _name = name;
        _cause = cause;
        _signalInfo = signalInfo;
    }
    return self;
}
- (id) JSONObject
{
//    @property(strong) NSString* name;
//    @property(strong) NSString* cause;
//    @property(strong) NRMACrashReport_SignalInfo* signalInfo;
    NSMutableDictionary* jsonDictionary = [[NSMutableDictionary alloc] init];
    [jsonDictionary setObject:self.name?:[NSNull null] forKey:kNRMA_CR_nameKey];
    [jsonDictionary setObject:self.cause?:[NSNull null] forKey:kNRMA_CR_causeKey];
    [jsonDictionary setObject:[self.signalInfo JSONObject]?:[NSNull null] forKey:kNRMA_CR_signalInfoKey];
    return jsonDictionary;
}

@end
