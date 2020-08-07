//
//  NRGCDOverride.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/5/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#ifdef __BLOCKS__
#import <Foundation/Foundation.h>
#import "NRMATraceController.h"
#import "NRMAMeasurements.h"
#import "NRLogger.h"
#import "NRMAExceptionHandler.h"
#import "NewRelicAgentInternal.h"
#import "NRMAFlags.h"

static void _enter_dispatch_method(NRMATrace* parentTrace, NSString* methodName, dispatch_queue_t queue) {
    //If user disables interaction tracing exit out!
    if (![NRMAFlags shouldEnableInteractionTracing]) {
        return;
    }

    NRLOG_VERBOSE(@"executing %@ block", methodName);
    if (parentTrace) {
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
        @try {
            #endif
            [NRMATraceController enterMethod:parentTrace name:methodName];
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
        } @catch (NSException* exception) {
            //log exception
            [NRMAExceptionHandler logException:exception
                                       class:@"NRTraceMachine"
                                    selector:@"enterMethod:name:"];
            [NRMATraceController cleanup];
        }
       #endif
        if (queue) {
            NSString* label = @"";
            const char* charLabel = dispatch_queue_get_label(queue);
            if (charLabel) {
                label = [NSString stringWithUTF8String:charLabel];
            }
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
            @try {
                #endif
                [[NRMATraceController currentTrace].threadInfo setThreadName:label];
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
            }  @catch (NSException *exception) {
                [NRMAExceptionHandler logException:exception
                                           class:@"TNRhreadInfo"
                                        selector:@"setThreadName:"];
                [NRMATraceController cleanup];
            }
            #endif
        }
    }
}

static void _exit_dispatch_method(NRMATrace* parentTrace) {
    if (![NRMAFlags shouldEnableInteractionTracing]) {
        return;
    }
    if (parentTrace) {
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
        @try {
            #endif
            [NRMATraceController exitMethod];
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
        }  @catch (NSException* exception) {
            //log exception
            [NRMAExceptionHandler logException:exception
                                       class:@"NRTraceMachine"
                                    selector:@"exitMethod"];

            [NRMATraceController cleanup];
        }
        #endif
    }
}

extern void NR__dispatch_async(dispatch_queue_t queue, dispatch_block_t block)
{
    NRLOG_VERBOSE(@"Enter dispatch_async");
    __block NRMATrace* parentTrace = [NRMATraceController currentTrace];
    dispatch_async(queue, ^{
        _enter_dispatch_method(parentTrace, @"dispatch_async", queue);
        block();
        _exit_dispatch_method(parentTrace);
    });
    NRLOG_VERBOSE(@"Leaving dispatch_async");
}

extern void NR__dispatch_sync(dispatch_queue_t queue, dispatch_block_t block)
{
    NRMATrace* parentTrace = [NRMATraceController currentTrace];
    dispatch_sync(queue, ^{
        _enter_dispatch_method(parentTrace, @"dispatch_sync", queue);
        block();
        _exit_dispatch_method(parentTrace);
    });
}

void NR__dispatch_after(dispatch_time_t when, dispatch_queue_t queue, dispatch_block_t block)
{
    NRMATrace* parentTrace = [NRMATraceController currentTrace];
    dispatch_after(when, queue, ^(void){
        _enter_dispatch_method(parentTrace, @"dispatch_after", queue);
        block();
        _exit_dispatch_method(parentTrace);
    });
}

void NR__dispatch_apply(size_t iterations, dispatch_queue_t queue, void(^block)(size_t))
{
    NRMATrace* parentTrace = [NRMATraceController currentTrace];
    dispatch_apply(iterations, queue, ^(size_t i) {
        _enter_dispatch_method(parentTrace, @"dispatch_apply", queue);
        block(i);
        _exit_dispatch_method(parentTrace);
    });
}

void NR__dispatch_once(dispatch_once_t *predicate, dispatch_block_t block)
{
    if (DISPATCH_EXPECT(*predicate, ~0l) != ~0l) {
        NRMATrace* parentTrace = [NRMATraceController currentTrace];
        dispatch_once(predicate, ^{
            _enter_dispatch_method(parentTrace, @"dispatch_once", NULL);
            block();
            _exit_dispatch_method(parentTrace);
        });
	}
}
#endif
