//
//
//  Created by Saxon D'Aubin on 5/23/12.
//  Copyright (c) 2012 New Relic. All rights reserved.
//

#import "NRMAMethodSwizzling.h"
#import <objc/runtime.h>
#import "NRLogger.h"

void* NRMASwapImplementations(Class c, SEL selector, IMP newImplementation)
{
    Method method = class_getInstanceMethod(c, selector);
    if (!method) {
        method = class_getClassMethod(c, selector);
    }

    if (method) {
        return method_setImplementation(method, newImplementation);
    }

    return nil;
}

void* NRMAReplaceClassMethod(Class c, SEL selector, IMP newImplementation)
{
    Method origMethod = class_getClassMethod(c, selector);
    IMP imp = method_setImplementation(origMethod, newImplementation);
    return imp;
}

void* NRMAReplaceInstanceMethod(Class c, SEL selector, IMP newImplementation)
{
    Method origMethod = class_getInstanceMethod(c, selector);
    IMP imp = method_getImplementation(origMethod);
    class_replaceMethod(c, selector, newImplementation, method_getTypeEncoding(origMethod));
    return imp;
}

void NRMASwapOrReplaceClassMethod(Class c, SEL originalSelector, SEL newSelector)
{
    Method origMethod = class_getClassMethod(c, originalSelector);
    Method newMethod = class_getClassMethod(c, newSelector);

    if (class_addMethod(object_getClass(c),originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(object_getClass(c), newSelector, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}

void NRMASwapOrReplaceInstanceMethod(Class c, SEL originalSelector, SEL newSelector)
{
    Method origMethod = class_getInstanceMethod(c, originalSelector);
    Method newMethod = class_getInstanceMethod(c, newSelector);
    if(class_addMethod(c, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(c, newSelector, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}

BOOL NRMASwizzleOrAddMethod(id self, SEL selector, SEL selectorAlias, IMP theImplementation)
{
    // if our wrapper is not already on the delegate
    if (![self respondsToSelector:selectorAlias]) {
        Class clazz = [self class];
        // if the delegate implements the original selector, swizzle that implementation
        if ([self respondsToSelector:selector]) {
            Method origMethod = class_getInstanceMethod(clazz, selector);
            IMP originalImplementation = method_getImplementation(origMethod);
            if (originalImplementation) {
                class_replaceMethod(clazz, selector, theImplementation, method_getTypeEncoding(origMethod));
                return class_addMethod(clazz, selectorAlias, originalImplementation, method_getTypeEncoding(origMethod));
            } else {
                //
                // `self` responds to `selector`, but the associated IMP is NULL. Probably a bug.
                //
                NRLOG_VERBOSE(@"Unable to find implementation for %@", NSStringFromSelector(selector));
                return false;
            }
        } else {
            // otherwise, just add the implementation
            return class_addMethod(clazz, selector, theImplementation, "v@:");
        }
    } else {
        return FALSE;
    }
}
