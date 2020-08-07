//
//  NRMACrashReport_Thread.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/6/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMACrashReport_Stack.h"
#import "NRMAJSON.h"

#define kNRMA_CR_crashedKey         @"crashed"
#define kNRMA_CR_registersKey       @"registers"
#define kNRMA_CR_threadNumberKey    @"threadNumber"
#define kNRMA_CR_threadIdKey        @"threadId"
#define kNRMA_CR_priorityKey        @"priority"
#define kNRMA_CR_stackKey           @"stack"
@interface NRMACrashReport_Thread : NSObject <NRMAJSONABLE>
@property(assign) BOOL crashed;
@property(strong) NSDictionary* registers;
@property(strong) NSNumber* threadNumber;
@property(strong) NSString* threadId;
@property(strong) NSNumber* priority;
@property(strong) NSArray* stackFrames;

- (instancetype) initWithCrashed:(BOOL)crashed
                       registers:(NSDictionary*)registers
                    threadNumber:(NSNumber*)threadNumber
                        threadId:(NSString*)threadId
                        priority:(NSNumber*)priority
                           stack:(NSMutableArray*)stackFrames;
@end
