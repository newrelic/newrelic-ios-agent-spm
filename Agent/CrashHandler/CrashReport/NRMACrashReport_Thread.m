//
//  NRMACrashReport_Thread.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/6/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMACrashReport_Thread.h"

@implementation NRMACrashReport_Thread

- (instancetype) initWithCrashed:(BOOL)crashed
                       registers:(NSDictionary*)registers
                    threadNumber:(NSNumber*)threadNumber
                        threadId:(NSString*)threadId
                        priority:(NSNumber*)priority
                           stack:(NSArray*)stackFrames
{
    self = [super init];
    if (self) {
        _crashed = crashed;
        _registers = registers;
        _threadNumber = threadNumber;
        _threadId = threadId;
        _priority = priority;
        _stackFrames = stackFrames;
    }
    return self;
}

- (id) JSONObject
{
    /* 
     @property(assign) BOOL crashed;
     @property(strong) NSDictionary* registers;
     @property(strong) NSNumber* threadNumber;
     @property(strong) NSString* threadIdentifier;
     @property(strong) NSNumber* priority;
     @property(strong) NRMACrashReport_Stack* stack;
     */
    NSMutableDictionary* jsonDictionary = [[NSMutableDictionary alloc] init];
    [jsonDictionary setObject:[NSNumber numberWithBool:self.crashed]?:[NSNull null] forKey:kNRMA_CR_crashedKey];
    [jsonDictionary setObject:self.registers?:[NSNull null] forKey:kNRMA_CR_registersKey];
    [jsonDictionary setObject:self.threadNumber?:[NSNull null] forKey:kNRMA_CR_threadNumberKey];
    [jsonDictionary setObject:self.threadId?:[NSNull null] forKey:kNRMA_CR_threadIdKey];
    [jsonDictionary setObject:self.priority?:[NSNull null] forKey:kNRMA_CR_priorityKey];
    NSMutableArray* stackFramesArray = [[NSMutableArray alloc] init];
    for (NRMACrashReport_Stack* stack in self.stackFrames) {
        [stackFramesArray addObject:[stack JSONObject]?:[NSNull null]];
    }
    [jsonDictionary setObject:stackFramesArray?:[NSNull null] forKey:kNRMA_CR_stackKey];
    return jsonDictionary;
}

@end
