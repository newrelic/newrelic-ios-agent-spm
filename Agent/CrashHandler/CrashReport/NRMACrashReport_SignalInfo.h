//
//  NRMACrashReport_SignalInfo.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/6/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAJSON.h"

#define kNRMA_CR_faultAddressKey    @"faultAddress"
#define kNRMA_CR_signalCodeKey      @"signalCode"
#define kNRMA_CR_signalNameKey      @"signalName"

@interface NRMACrashReport_SignalInfo : NSObject <NRMAJSONABLE>
@property(strong) NSString* faultAddress;
@property(strong) NSString* signalCode;
@property(strong) NSString* signalName;

- (instancetype) initWithFaultAddress:(NSString*)faultAddress
                           signalCode:(NSString*)signalCode
                           signalName:(NSString*)signalName;

@end
