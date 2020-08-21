//
//  NRMACrashReport_SignalInfo.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/6/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMACrashReport_SignalInfo.h"

@implementation NRMACrashReport_SignalInfo

- (instancetype) initWithFaultAddress:(NSString*)faultAddress
                           signalCode:(NSString*)signalCode
                           signalName:(NSString*)signalName
{
    self = [super init];
    if (self) {
        _faultAddress = faultAddress;
        _signalCode = signalCode;
        _signalName = signalName;
    }
    return self;
}

- (id) JSONObject
{
   /*
    @property(strong) NSString* faultAddress;
    @property(strong) NSString* signalCode;
    @property(strong) NSString* signalName;
    */
    NSMutableDictionary* jsonDictionary = [[NSMutableDictionary alloc] init];
    jsonDictionary[kNRMA_CR_faultAddressKey] = self.faultAddress ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_signalCodeKey] = self.signalCode ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_signalNameKey] = self.signalName ?: (id) [NSNull null];
    return jsonDictionary;
}
@end
