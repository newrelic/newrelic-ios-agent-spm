//
//  NRMACrashReport_Symbol.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/6/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAJSON.h"

#define kNRMA_CR_symbolStartAddrKey @"symbolStartAddr"
#define kNRMA_CR_symbolNameKey      @"symbolName"
@interface NRMACrashReport_Symbol : NSObject <NRMAJSONABLE>
@property(strong) NSString* symbolStartAddr;
@property(strong) NSString* symbolName;

- (instancetype) initWithSymbolStartAddr:(NSString*)symbolStartAddr
                              symbolName:(NSString*)symbolName;

@end
