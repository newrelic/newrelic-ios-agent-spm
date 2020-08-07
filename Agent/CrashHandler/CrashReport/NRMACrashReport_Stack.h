//
//  NRMACrashReport_Stack.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/6/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMACrashReport_Symbol.h"
#import "NRMAJSON.h"

#define kNRMA_CR_instructionPtrKey @"instructionPointer"
#define kNRMA_CR_symbolKey         @"symbolInfo"

@interface NRMACrashReport_Stack : NSObject <NRMAJSONABLE>
@property(strong) NSString* instructionPointer;
@property(strong) NRMACrashReport_Symbol* symbol;

- (instancetype) initWithInstructionPointer:(NSString*)instructionPtr
                           symbol:(NRMACrashReport_Symbol*)symbol;
@end
