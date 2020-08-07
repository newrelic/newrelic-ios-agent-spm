//
//  NRMAGestureRecognizerInstrumentation.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/14/16.
//  Copyright © 2016 New Relic. All rights reserved.
//

#import "NRMAGestureRecognizerInstrumentation.h"
#import "NRMAMethodSwizzling.h"
#import "NewRelicAgentInternal.h"
#import "NRMAGestureProcessor.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "NRMAFlags.h"
#import "NRMAUserActionBuilder.h"

@implementation NRMAGestureRecognizerInstrumentation

id (*NRMA__initWithTarget_action)(id,SEL,id,SEL);
void (*NRMA__addTarget_action)(id,SEL,id,SEL);
void (*NRMA__removeTarget_action)(id,SEL,id,SEL);

// Used to instrument all assigned recognizer delegate-actions.
SEL instrument_target_message(id target, SEL msg) {
    // Instrumentation block!
    void(^block)(id _self, id sender) = ^(id _self, id sender){ //this is why we can't have nice things
        // instrumentation for action msg on target
        if ([NRMAFlags shouldEnableGestureInstrumentation]) {
            if ([sender isKindOfClass:[UIGestureRecognizer class]] && ((UIGestureRecognizer*)sender).state == UIGestureRecognizerStateEnded) {
                NRMAUserAction* uiGesture = [NRMAUserActionBuilder buildWithBlock:^(NRMAUserActionBuilder *builder) {
                    [builder withActionType:NSStringFromClass([sender class])];
                    [builder fromMethod:NSStringFromSelector(msg)];
                    [builder fromClass:NSStringFromClass([target class])];
                    [builder withAccessibilityId:[NRMAGestureProcessor getAccessibility:((UIGestureRecognizer*)sender).view]];
                    [builder atCoordinates:NSStringFromCGPoint([((UIGestureRecognizer*)sender) locationInView:nil])];
                    [builder withElementFrame:[NRMAGestureProcessor getFrame:((UIGestureRecognizer*)sender).view]];
                }];
                [[NewRelicAgentInternal sharedInstance].gestureFacade recordUserAction:uiGesture];
            }
        }
        
        ((void(*)(id,SEL,id))[_self methodForSelector:msg])(_self,msg,sender);
    };
    
    // replace original target-message with instrumented target-message block from above.
    SEL newMsg = NSSelectorFromString([NSString stringWithFormat:@"nrma_%@",NSStringFromSelector(msg)]);
    if (![target respondsToSelector:newMsg]) { // ensure it isn't already instrumented
        Method m = class_getInstanceMethod([target class],msg);
        class_addMethod([target class], newMsg, imp_implementationWithBlock(block),method_getTypeEncoding(m));
    }
    return newMsg;
}

//instruments assigned target-action via init method
id initWithTarget_action(id self, SEL _cmd, id target, SEL msg) {
    SEL newMsg = msg;
    if (target != nil && msg != nil) { //if target or msg is nil, there's nothing to do.
        newMsg = instrument_target_message(target, msg);
    }
    return NRMA__initWithTarget_action(self,_cmd,target,newMsg);
    
}

//instruments assigned target-action via addTarget:action: method
void addTarget_action(id self, SEL _cmd, id target, SEL msg) {
    SEL newMsg = msg;

    if (target != nil && msg != nil) { //if target or msg is nil, there's nothing to do.
        newMsg = instrument_target_message(target, msg);
    }

    return NRMA__addTarget_action(self,_cmd,target,newMsg);
}

//removed the instrumented target-method from the recognizer, but leaves the target
//instrumented in case it is re-added to a recognizer.
void removeTarget_action(id self, SEL _cmd, id target, SEL msg) {
    SEL newMsg = msg;
    if (target != nil && msg != nil) {
        newMsg = NSSelectorFromString([NSString stringWithFormat:@"nrma_%@",NSStringFromSelector(msg)]);
    }
    return NRMA__removeTarget_action(self,_cmd,target,newMsg);
}

+ (BOOL) instrumentUIGestureRecognizer
{
    id clazz = objc_getClass("UIGestureRecognizer");
    
    if(clazz) {
        if (NRMA__addTarget_action != NULL || NRMA__initWithTarget_action != NULL || NRMA__removeTarget_action != NULL) return NO;
        
        if (![NRMAGestureRecognizerInstrumentation instrumentUIGestureInitWithTarget]) {
            return NO;
        }

        if (![NRMAGestureRecognizerInstrumentation instrumentUIGestureAddTarget]) {
            [NRMAGestureRecognizerInstrumentation deinstrumentUIGestureRecognizerInitWithTarget];
            return NO;
        }
        
        if (![NRMAGestureRecognizerInstrumentation instrumentUIGestureRemoveTarget]) {
            [NRMAGestureRecognizerInstrumentation deinstrumentUIGestureAddTarget];
            [NRMAGestureRecognizerInstrumentation deinstrumentUIGestureRecognizerInitWithTarget];
            return NO;
        }
        
        return YES;
    }
    return NO;
}

+ (BOOL) deinstrumentUIGestureRecognizer
{
    return [NRMAGestureRecognizerInstrumentation deinstrumentUIGestureAddTarget] &&
            [NRMAGestureRecognizerInstrumentation deinstrumentUIGestureRecognizerInitWithTarget] &&
            [NRMAGestureRecognizerInstrumentation deinstrumentUIGestureRemoveTarget];
}

// instrumentation helpers.

+ (BOOL) instrumentUIGestureInitWithTarget {

    return (NRMA__initWithTarget_action = NRMAReplaceInstanceMethod([UIGestureRecognizer class],@selector(initWithTarget:action:), (IMP)initWithTarget_action)) != NULL;
}

+ (BOOL) instrumentUIGestureAddTarget
{
    return (NRMA__addTarget_action = NRMAReplaceInstanceMethod([UIGestureRecognizer class], @selector(addTarget:action:), (IMP)addTarget_action)) != NULL;
}

+ (BOOL) instrumentUIGestureRemoveTarget {
    return (NRMA__removeTarget_action = NRMAReplaceInstanceMethod([UIGestureRecognizer class], @selector(removeTarget:action:), (IMP)removeTarget_action)) != NULL;
}


+ (BOOL) deinstrumentUIGestureRecognizerInitWithTarget
{
    if((NRMAReplaceInstanceMethod([UIGestureRecognizer class],@selector(initWithTarget:action:),(IMP)NRMA__initWithTarget_action)) == (IMP)initWithTarget_action) {
        NRMA__initWithTarget_action = NULL;
        return YES;
    }
    return NO;
}

+ (BOOL) deinstrumentUIGestureAddTarget
{
    if((NRMAReplaceInstanceMethod([UIGestureRecognizer class],@selector(addTarget:action:),(IMP)NRMA__addTarget_action)) == (IMP)addTarget_action) {
        NRMA__addTarget_action = NULL;
        return YES;
    }
    return NO;
}

+ (BOOL) deinstrumentUIGestureRemoveTarget
{
    if((NRMAReplaceInstanceMethod([UIGestureRecognizer class],@selector(removeTarget:),(IMP)NRMA__removeTarget_action)) == (IMP)removeTarget_action) {
        NRMA__removeTarget_action = NULL;
        return YES;
    }
    return NO;
}




@end
