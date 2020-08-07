//
//  NRMethodTrace.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/7/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMACustomTrace.h"
#import "NRMATraceController.h"
#import "NRMAExceptionHandler.h"
#import "NRLogger.h"
#import "NRMATrace.h"
#import <objc/runtime.h>


NSString * const kNRTraceAssociatedKey = @"_nr_traceTimerAssociatedKey";
@implementation NRMACustomTrace

+ (void) startTracingMethod:(SEL)selector
                 objectName:(NSString*)objectName
                      timer:(NRTimer*)timer
                   category:(enum NRTraceType)category
{

    if (!timer) {
        return;
    }

#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
    @try {
#endif
        [NRMATraceController enterMethod:selector
                         fromObjectNamed:objectName
                             parentTrace:[NRMATraceController currentTrace]
                           traceCategory:category
                               withTimer:timer];

#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                   class:NSStringFromClass([self class])
                                selector:NSStringFromSelector(_cmd)];
        [NRMATraceController cleanup];
    }
#endif
}

+ (void) endTracingMethodWithTimer:(NRTimer*)timer
{

    if (timer == nil) {
        return;
    }

    NRMATrace *currentThreadTrace = [NRMATraceController currentTrace];
    NRMATrace* associatedTrace = objc_getAssociatedObject(timer, (__bridge const void *)(kNRTraceAssociatedKey));

    if (!associatedTrace) {
        NRLOG_ERROR(@"Custom endTracingMethodWithTimer: called w/out paired startTracingMethod:...");
        return;
    }
    if (associatedTrace != currentThreadTrace) {
        NRLOG_ERROR(@"Custom endTracingMethodWithTimer: timer does not match current startTracingMethod:... context (expected context: %@, timer context: %@)",
                    currentThreadTrace.name, associatedTrace.name);
        return;
    }

    //remove the associated object
    objc_setAssociatedObject(timer, (__bridge const void *)(kNRTraceAssociatedKey), Nil, OBJC_ASSOCIATION_ASSIGN);
    
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
    @try {
        #endif
        [NRMATraceController exitCustomMethodWithTimer:timer];
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
    } @catch (NSException *exception) {
        [NRMAExceptionHandler logException:exception
                                   class:NSStringFromClass([self class])
                                selector:NSStringFromSelector(_cmd)];
        [NRMATraceController cleanup];
    }
#endif
}


@end

NSString* NSStringFromNRMATraceType (enum NRTraceType category) {
    switch (category) {
        case NRTraceTypeNone:
            return @"None";
            break;
        case NRTraceTypeViewLoading:
            return @"View Loading";
            break;
        case NRTraceTypeLayout:
            return @"Layout";
            break;
        case NRTraceTypeDatabase:
            return @"Database";
            break;
        case NRTraceTypeImages:
            return @"Images";
            break;
        case NRTraceTypeJson:
            return @"JSON";
            break;
        case NRTraceTypeNetwork:
            return @"Network";
            break;
        default:
            return @"None";
            break;
    }
    return @"None";
}
