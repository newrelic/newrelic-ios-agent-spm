//
//  NRMATableViewIntrumentation.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/10/16.
//  Copyright © 2016 New Relic. All rights reserved.
//

#import "NRMATableViewIntrumentation.h"
#import "NRMAMethodSwizzling.h"
#import "NewRelicAgentInternal.h"
#import "NRMAGestureProcessor.h"
#import <objc/runtime.h>
#import "NRMAUserActionBuilder.h"
#import "NRMAFlags.h"


#define kNRMA_DidSelectRowAtIndexPath @"tableView:didSelectRowAtIndexPath:"
#define kNRMA_isInstrumented @"NRMA_isInstrumented"

@implementation NRMATableViewIntrumentation

static void (*NRMA__setDelegate)(id self, SEL _cmd, id<UITableViewDelegate>);

static BOOL NRMA_isInstrumented(id self, SEL _cmd) {
    return YES;
}

/*
 * To capture cell selection on a table view the table view delegate must be
 * instrumented. The instrumentation must be generic, so it can handle any
 * number of delegates.
 * The method 'NRMA_isInstrumented' is also added to the delegate to identify
 * instrumented delegates if they are re-added as the tableView delegate.
 *
 * This class will instrument 2 methods:
 *  UITableView setDelegate:
 *  id<UITableViewDelegate> tableView:didSelectRowAtIndexPath:
 *
 * Instrumenting setDelegate: allows for the instrumentation of the delegate
 * object used.
 *
 */
static void setDelegate(id self, SEL _cmd, id<UITableViewDelegate> _delegate) {
    //instrument delegate
    SEL didSelectRowAtIndexPath = NSSelectorFromString(kNRMA_DidSelectRowAtIndexPath);

    if ([_delegate respondsToSelector:didSelectRowAtIndexPath]
        && ![_delegate respondsToSelector:NSSelectorFromString(kNRMA_isInstrumented)]){

        Method m = class_getInstanceMethod([_delegate class],
                                           didSelectRowAtIndexPath);
        __block IMP imp = method_getImplementation(m);

        void(^block)(id, id, id) = ^(id _self, id tableView, id indexPath) {

            if([NRMAFlags shouldEnableGestureInstrumentation]) {
                NRMAUserAction* uiGesture = [NRMAUserActionBuilder buildWithBlock:^(NRMAUserActionBuilder *builder) {
                    [builder withActionType:@"tableViewRowTap"];
                    [builder fromMethod:kNRMA_DidSelectRowAtIndexPath];
                    [builder fromClass:NSStringFromClass([_self class])];
                    [builder withAccessibilityId:[NRMAGestureProcessor getAccessibility:tableView]];
                    [builder withElementFrame:[NRMAGestureProcessor getFrame:tableView]];
                }];
                [[NewRelicAgentInternal sharedInstance].gestureFacade recordUserAction:uiGesture];
            }

            if (imp == nil) {
                if ([_self respondsToSelector:didSelectRowAtIndexPath]){
                    NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[_self methodSignatureForSelector:didSelectRowAtIndexPath]];
                    [inv setSelector:didSelectRowAtIndexPath];
                    [inv setArgument:&tableView atIndex:2];
                    [inv setArgument:&indexPath atIndex:3];
                    [_self forwardInvocation:inv];
                }
            } else {
                ((void(*)(id,SEL,id,id))imp)(_self, didSelectRowAtIndexPath,tableView,indexPath);
            }
        };


        class_replaceMethod([_delegate class], didSelectRowAtIndexPath, imp_implementationWithBlock(block), method_getTypeEncoding(m));

        class_addMethod([_delegate class],
                        NSSelectorFromString(kNRMA_isInstrumented),
                        (IMP)NRMA_isInstrumented,
                        "B@:");

    }
    NRMA__setDelegate(self, _cmd, _delegate);
}


+ (BOOL) instrument {
    Class clazz = objc_getClass("UITableView");
    if (clazz) {
        if (NRMA__setDelegate != NULL) return NO;
        NRMA__setDelegate = NRMAReplaceInstanceMethod(clazz, @selector(setDelegate:), (IMP)setDelegate);
        return YES;
    }
    return NO;
}

+ (BOOL) deinstrument {
    Class clazz = objc_getClass("UITableView");
    if (clazz) {
        if (NRMA__setDelegate == NULL) return NO;
        NRMAReplaceInstanceMethod(clazz, @selector(setDelegate:), (IMP)NRMA__setDelegate);
        NRMA__setDelegate = NULL;
        return YES;
    }
    return NO;
}
@end
