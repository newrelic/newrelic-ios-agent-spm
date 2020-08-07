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
    [jsonDictionary setObject:self.instructionPointer?:[NSNull null] forKey:kNRMA_CR_instructionPtrKey];
    [jsonDictionary setObject:[self.symbol JSONObject]?:[NSNull null] forKey:kNRMA_CR_symbolKey];
    return jsonDictionary;
}
@end
