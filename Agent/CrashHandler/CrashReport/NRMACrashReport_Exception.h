//
//  NRMACrashReport_Exception.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/6/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMACrashReport_SignalInfo.h"
#import "NRMAJSON.h"

#define kNRMA_CR_nameKey       @"name"
#define kNRMA_CR_causeKey      @"cause"
#define kNRMA_CR_signalInfoKey @"signalInfo"

@interface NRMACrashReport_Exception : NSObject <NRMAJSONABLE>
@property(strong) NSString* name;
@property(strong) NSString* cause;
@property(strong) NRMACrashReport_SignalInfo* signalInfo;
- (instancetype) initWithName:(NSString*)name
                        cause:(NSString*)cause
                   signalInfo:(NRMACrashReport_SignalInfo*)signalInfo;
@end
