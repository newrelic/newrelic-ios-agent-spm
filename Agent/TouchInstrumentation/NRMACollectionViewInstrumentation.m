//
//  NRMACollectionViewInstrumentation.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/28/18.
//  Copyright © 2018 New Relic. All rights reserved.
//

#import "NRMACollectionViewInstrumentation.h"
#import <UIKit/UIKit.h>

#import "NRMATableViewIntrumentation.h"
#import "NRMAMethodSwizzling.h"
#import "NewRelicAgentInternal.h"
#import "NRMAGestureProcessor.h"
#import <objc/runtime.h>
#import "NRMAUserActionBuilder.h"
#import "NRMAFlags.h"

#define kNRMA_didSelectItemAtIndexPath @"collectionView:didSelectItemAtIndexPath:"
#define kNRMA_isInstrumented @"NRMA_isInstrumented"

@implementation NRMACollectionViewInstrumentation

static void (*NRMA__setDelegate)(id self, SEL _cmd, id<UICollectionViewDelegate>);

static BOOL NRMA_isInstrumented(id self, SEL _cmd) {
    return YES;
}


static void setDelegate(id self, SEL _cmd, id<UICollectionViewDelegate> _delegate) {
    SEL collectionView_didSelectItemAtIndexPath = NSSelectorFromString(kNRMA_didSelectItemAtIndexPath);
    SEL isInstrumented = NSSelectorFromString(kNRMA_isInstrumented);

    if ([_delegate respondsToSelector:collectionView_didSelectItemAtIndexPath]
        && ![_delegate respondsToSelector:isInstrumented]) {

        Method m = class_getInstanceMethod([_delegate class],
                                           collectionView_didSelectItemAtIndexPath);

        __block IMP imp = method_getImplementation(m);

        void(^block)(id, id, id) = ^(id _self, id collectionView, id indexPath) {

            if([NRMAFlags shouldEnableGestureInstrumentation]) {
                NRMAUserAction* uiGesture = [NRMAUserActionBuilder buildWithBlock:^(NRMAUserActionBuilder *builder) {
                    [builder withActionType:@"collectionViewItemTap"];
                    [builder fromMethod:kNRMA_didSelectItemAtIndexPath];
                    [builder fromClass:NSStringFromClass([_self class])];
                    [builder withAccessibilityId:[NRMAGestureProcessor getAccessibility:collectionView]];
                    [builder withElementFrame:[NRMAGestureProcessor getFrame:collectionView]];
                }];
                [[NewRelicAgentInternal sharedInstance].gestureFacade recordUserAction:uiGesture];
            }

            if (imp == nil) {
                if ([_self respondsToSelector:collectionView_didSelectItemAtIndexPath]) {
                    NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[_self methodSignatureForSelector:collectionView_didSelectItemAtIndexPath]];
                    [inv setSelector:collectionView_didSelectItemAtIndexPath];
                    [inv setArgument:&collectionView atIndex:2];
                    [inv setArgument:&indexPath atIndex:3];
                    [_self forwardInvocation:inv];
                }
            } else {
                ((void (*)(id, SEL, id, id))imp)(_self, collectionView_didSelectItemAtIndexPath, collectionView, indexPath);
            }
        };

        class_replaceMethod([_delegate class], collectionView_didSelectItemAtIndexPath, imp_implementationWithBlock(block), method_getTypeEncoding(m));

        class_addMethod([_delegate class],
                        isInstrumented,
                        (IMP)NRMA_isInstrumented,
                        "B@:");
    }



    NRMA__setDelegate(self, _cmd,_delegate);
}

+ (BOOL) instrument {
    Class clazz = objc_getClass("UICollectionView");
    if (clazz) {
        if (NRMA__setDelegate != NULL) return NO;
        NRMA__setDelegate = NRMAReplaceInstanceMethod(clazz, @selector(setDelegate:), (IMP)setDelegate);
        return YES;
    }
    return NO;
}

+ (BOOL) deinstrument {
    Class clazz = objc_getClass("UICollectionView");
    if (clazz) {
        if (NRMA__setDelegate == NULL) return NO;
        NRMAReplaceInstanceMethod(clazz, @selector(setDelegate:), (IMP)NRMA__setDelegate);
        NRMA__setDelegate = NULL;
        return YES;
    }
    return NO;
}

@end
