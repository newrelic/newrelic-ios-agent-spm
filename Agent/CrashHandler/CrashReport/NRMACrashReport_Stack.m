//
//  NRMACrashReport_Stack.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/6/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMACrashReport_Stack.h"

@implementation NRMACrashReport_Stack

- (instancetype) initWithInstructionPointer:(NSString*)instructionPtr
                                     symbol:(NRMACrashReport_Symbol*)symbol
{
    self = [super init];
    if (self) {
        _instructionPointer = instructionPtr;
        _symbol = symbol;
    }
    return self;
}

- (id) JSONObject
{
    NSMutableDictionary* jsonDictionary = [[NSMutableDictionary alloc] init];
    jsonDictionary[kNRMA_CR_instructionPtrKey] = self.instructionPointer ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_symbolKey] = [self.symbol JSONObject] ?: (id) [NSNull null];
    return jsonDictionary;
}
@end
