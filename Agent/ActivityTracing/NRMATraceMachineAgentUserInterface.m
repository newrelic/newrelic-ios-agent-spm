//
//  NRMATraceMachineAgentUserInterface.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 7/9/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMATraceMachineAgentUserInterface.h"
#import "NRMAExceptionHandler.h"
#import "NewRelicInternalUtils.h"
#import "NRMATraceMachine.h"
#import <objc/runtime.h>
#import "NRLogger.h"


@interface NRMATraceController ()
+ (NRMATraceMachine*) traceMachine;
@end

static NSString * const kNRMAActivityIdentifierKey = @"com.newrelic.customapi.tracemachine.customActivityIdentifier";

@implementation NRMATraceMachineAgentUserInterface

+ (NSString*) startCustomActivity:(NSString*)name
{

    if (![name length]) {
        NRLOG_ERROR(@"Attempted to call startCustomActivity with empty \"name\" value. Aborting custom activity.");
        return nil;
    }

    NSString* cleansedName = [NewRelicInternalUtils cleanseStringForCollector:name];

    if (![cleansedName length]) {
        NRLOG_ERROR(@"name = \"%@\" passed to \"start interaction\" contains no legal characters. Please constrain characters to only alpha-numeric values. Aborting custom activity.",name);
        return nil;
    }

    // now we need to start an activity and capture it to
    //associate it with a guid.
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    NSString* activityIdentifier = CFBridgingRelease(CFUUIDCreateString(NULL, theUUID));
    CFRelease(theUUID);

    @synchronized(kNRMAStartAndEndTracingLock) { //synchronized with the start/end lock
        //to ensure we can set an associated object on the newly created trace machine
        //before something comes along and completes the activity trace (and creates a new one)!
        [NRMATraceController startTracingWithName:cleansedName interactionObject:nil];
        NRMATraceMachine* localTraceMachine = [self traceMachine]; //the new tracemachine
        @synchronized(localTraceMachine) {
            objc_setAssociatedObject(localTraceMachine, (__bridge const void*)kNRMAActivityIdentifierKey, activityIdentifier, OBJC_ASSOCIATION_RETAIN);
            localTraceMachine.activityTrace.initiatingObjectIdentifier = kNRMACustomInteractionIdentifier;
        }
    }
    return activityIdentifier;
}


+ (void) stopCustomActivity:(NSString*)activityIdentifier
{
    @synchronized(kNRMAStartAndEndTracingLock) {
        NRMATraceMachine* localActivityTrace = [self traceMachine];
        @synchronized(localActivityTrace) {
            NSString* currentActivityIdentifier = objc_getAssociatedObject(localActivityTrace, (__bridge const void *)(kNRMAActivityIdentifierKey));
            if ([currentActivityIdentifier isEqualToString:activityIdentifier]) {
                [NRMATraceController completeActivityTrace];
            }
        }
    }
}

@end
