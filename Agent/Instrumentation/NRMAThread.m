//
//  NRMAThread.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/9/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//
#import "NRMATraceController.h"
#import "NRMAThread.h"
#import "NRMATrace.h"
#import "NRMAMethodSwizzling.h"
#import "NRMAThreadTransition.h"
#import "NRMAExceptionHandler.h"
#import <objc/runtime.h>

id   (*NRMA__NSThread__initWithTarget__selector__object)(id,SEL,id,SEL,id);




static id initWithTarget_selector_object(id self,
                                         SEL _cmd,
                                         id target,
                                         SEL selector,
                                         id argument)
{
    NRMAThreadTransition* threadTransition = [[NRMAThreadTransition alloc] init];
    threadTransition.selector = selector;
    threadTransition.target = target;
    threadTransition.argument = argument;
    threadTransition.parent = [NRMATraceController currentTrace];
    return NRMA__NSThread__initWithTarget__selector__object(self,
                                                          _cmd,
                                                          [[NRMAThread alloc] init],
                                                          @selector(enteredNewThreadWithTransition:),
                                                          threadTransition);
    
}


@implementation NRMAThread

+ (BOOL) instrumentNSThread
{
    id clazz = objc_getClass("NSThread");
    if (clazz) {
        if (NRMA__NSThread__initWithTarget__selector__object == NULL) {
            NRMA__NSThread__initWithTarget__selector__object = NRMAReplaceInstanceMethod([NSThread class],
                                                                                     @selector(initWithTarget:selector:object:),
                                                                                     (IMP)initWithTarget_selector_object);
        }
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL) deinstrumentNSThread
{
    NRMA__NSThread__initWithTarget__selector__object = NRMAReplaceInstanceMethod([NSThread class], @selector(initWithTarget:selector:object:), (IMP)NRMA__NSThread__initWithTarget__selector__object);
    BOOL success = NRMA__NSThread__initWithTarget__selector__object == initWithTarget_selector_object;
    NRMA__NSThread__initWithTarget__selector__object = NULL;
    return success;
}

- (void) enteredNewThreadWithTransition:(NRMAThreadTransition*)transition
{
    @autoreleasepool {
        BOOL didExecuteStart = NO;
        if ([NRMATraceController isTracingActive]) {
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
            @try {
#endif
                didExecuteStart = [NRMATraceController enterMethod:transition.parent
                                                         name:[NSString stringWithFormat:@"%@#%@",
                                                               NSStringFromClass([transition.target class]),
                                                               NSStringFromSelector(transition.selector)]];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
            } @catch (NSException* exception) {
                [NRMAExceptionHandler logException:exception
                                           class:NSStringFromClass([self class])
                                        selector:NSStringFromSelector(_cmd)];
            [NRMATraceController cleanup];
                didExecuteStart = NO;
            }
            #endif
        }
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [transition.target performSelector:transition.selector withObject:transition.argument];
        #pragma diagnostic pop
        //record endtime;
        if (didExecuteStart) {
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
            @try {
#endif
                [NRMATraceController exitMethod];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
            }  @catch (NSException* exception) {
                //log exception
                [NRMAExceptionHandler logException:exception
                                           class:NSStringFromClass([self class])
                                        selector:NSStringFromSelector(_cmd)];
            [NRMATraceController cleanup];
                
            }
#endif
        }
    }
}



@end
