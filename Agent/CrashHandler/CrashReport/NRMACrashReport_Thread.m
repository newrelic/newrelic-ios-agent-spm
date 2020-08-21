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
                           stack:(NSMutableArray*)stackFrames
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
    jsonDictionary[kNRMA_CR_crashedKey] = @(self.crashed) ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_registersKey] = self.registers ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_threadNumberKey] = self.threadNumber ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_threadIdKey] = self.threadId ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_priorityKey] = self.priority ?: (id) [NSNull null];
    NSMutableArray* stackFramesArray = [[NSMutableArray alloc] init];
    for (NRMACrashReport_Stack* stack in self.stackFrames) {
        [stackFramesArray addObject:[stack JSONObject]?:[NSNull null]];
    }
    jsonDictionary[kNRMA_CR_stackKey] = stackFramesArray ?: (id) [NSNull null];
    return jsonDictionary;
}

@end
