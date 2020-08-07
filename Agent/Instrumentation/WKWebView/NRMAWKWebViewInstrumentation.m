//
// Created by Bryce Buchanan on 1/4/17.
// Copyright (c) 2017 New Relic. All rights reserved.
//

#import "NRMAWKWebViewInstrumentation.h"
#import "NRMAWKWebViewNavigationDelegate.h"
#import <UIKit/UIKit.h>


//NOTE: this files has ARC disabled.

static id initWithFrame_configuration(id self, SEL _cmd, CGRect frame, id configuration);
static id initWithCoder(id self, SEL _cmd, id coder);

static id navigationDelegate(id self, SEL _cmd);
static void setNavigationDelegate(id self, SEL _cmd, id delegate);
static void dealloc(id self, SEL _cmd);

#if !TARGET_OS_TV
id (*NRMA__WKWebView_initWithFrame_configuration)(id self,
                                                    SEL _cmd,
                                                    CGRect frame,
                                                    id configuration);
id (*NRMA__WKWebView_initWithCoder)(id self,
                                      SEL _cmd,
                                      NSCoder* coder);


// IMPORTANTE: calling this method seems to increment the retain count by 1.
//ensure that this method is wrapped inside an autorelease pool whenever used.
id (*NRMA__WKWebView_navigationDelegate)(id self,
                                         SEL _cmd);

void (*NRMA__WKWebView_setNavigationDelegate)(id self,
                                              SEL _cmd,
                                              id delegate);

void (*NRMA__WKWebView_dealloc)(id self, SEL _cmd);

#endif

@implementation NRMAWKWebViewInstrumentation

+ (void) instrument {
#if !TARGET_OS_TV
    Class clazz = objc_getClass("WKWebView");
    if (clazz) {

        SEL initWithFrameSelector = @selector(initWithFrame:configuration:);
        Method initWithFrameMethod = class_getInstanceMethod(clazz, initWithFrameSelector);

        NRMA__WKWebView_initWithFrame_configuration = (id(*)(id,SEL,CGRect,id))class_replaceMethod(clazz,
                                                                                                     initWithFrameSelector,
                                                                                                     (IMP)initWithFrame_configuration,
                                                                                                     method_getTypeEncoding(initWithFrameMethod));

        SEL initWithCoderSelector = @selector(initWithCoder:);
        Method initWithCoderMethod = class_getInstanceMethod(clazz, initWithCoderSelector);
        NRMA__WKWebView_initWithCoder = (id(*)(id,SEL,id))class_replaceMethod(clazz,
                                                                                initWithCoderSelector,
                                                                                (IMP)initWithCoder,
                                                                                method_getTypeEncoding(initWithCoderMethod));

        SEL navigationDelegateSelector = @selector(navigationDelegate);
        Method navigationSelectorMethod = class_getInstanceMethod(clazz, navigationDelegateSelector);
        NRMA__WKWebView_navigationDelegate = (id(*)(id,SEL))class_replaceMethod(clazz,
                                                                                navigationDelegateSelector,
                                                                                (IMP)navigationDelegate,
                                                                                method_getTypeEncoding(navigationSelectorMethod));

        SEL setNavigationDelegateSelector = @selector(setNavigationDelegate:);
        Method setNavigationDelegateMethod = class_getInstanceMethod(clazz, setNavigationDelegateSelector);
        NRMA__WKWebView_setNavigationDelegate = (void(*)(id,SEL,id))class_replaceMethod(clazz,
                                                                                        setNavigationDelegateSelector,
                                                                                        (IMP)setNavigationDelegate,
                                                                                        method_getTypeEncoding(setNavigationDelegateMethod));

        SEL deallocSelector = @selector(dealloc);
        Method deallocMethod = class_getInstanceMethod(clazz, deallocSelector);
        NRMA__WKWebView_dealloc = (void(*)(id,SEL))class_replaceMethod(clazz,
                                                                       deallocSelector,
                                                                       (IMP)dealloc,
                                                                       method_getTypeEncoding(deallocMethod));
    }

#endif
}

+ (void) deinstrument {
#if !TARGET_OS_TV
    Class clazz = objc_getClass("WKWebView");
    if (clazz) {
        SEL initWithFrameSelector = @selector(initWithFrame:configuration:);
        method_setImplementation(class_getInstanceMethod(clazz, initWithFrameSelector),(IMP)NRMA__WKWebView_initWithFrame_configuration);


        SEL initWithCoderSelector = @selector(initWithCoder:);
        method_setImplementation(class_getInstanceMethod(clazz, initWithCoderSelector),(IMP)NRMA__WKWebView_initWithCoder);


        SEL navigationDelegateSelector = @selector(navigationDelegate);
        method_setImplementation(class_getInstanceMethod(clazz, navigationDelegateSelector),(IMP)NRMA__WKWebView_navigationDelegate);


        SEL setNavigationDelegateSelector = @selector(setNavigationDelegate:);
        method_setImplementation(class_getInstanceMethod(clazz, setNavigationDelegateSelector), (IMP)NRMA__WKWebView_setNavigationDelegate);
    }
#endif
}

@end


void dealloc(id self, SEL _cmd) {
    #if !TARGET_OS_TV
    @autoreleasepool {
        [NRMA__WKWebView_navigationDelegate(self, @selector(navigationDelegate)) release];
        NRMA__WKWebView_dealloc(self, _cmd);
    }
    #endif
}
#if !TARGET_OS_TV
static id navigationDelegate(id self, SEL _cmd) {
    @autoreleasepool {
        
    id delegate = NRMA__WKWebView_navigationDelegate(self,_cmd);
    if ([delegate isKindOfClass:[NRMAWKWebViewNavigationDelegate class]]) {
        return ((NRMAWKWebViewNavigationDelegate*)delegate).realDelegate;
    }
    return delegate;
    }
}
#endif
static void setNavigationDelegate(id self, SEL _cmd, id delegate) {
#if !TARGET_OS_TV
    @autoreleasepool {
        id lastDelegate = NRMA__WKWebView_navigationDelegate(self,_cmd);
        if ([delegate isKindOfClass:[NRMAWKWebViewNavigationDelegate class]]) {
            ((NRMAWKWebViewNavigationDelegate*)delegate).realDelegate = delegate;
        }
        id value = [[NRMAWKWebViewNavigationDelegate alloc] initWithOriginalDelegate:delegate];
        NRMA__WKWebView_setNavigationDelegate(self, _cmd, value);
        
        if (lastDelegate != nil && lastDelegate != delegate) {
            //don't try to release nil
            //don't release the last delegate if the the same object is being passed as the incoming delegate.
            [lastDelegate release];
        }
    }
#endif
}

#if !TARGET_OS_TV
id initWithCoder(id self, SEL _cmd, id coder) {
     id result = NRMA__WKWebView_initWithCoder(self, _cmd, coder);
    NRMA__WKWebView_setNavigationDelegate(result, _cmd, [[NRMAWKWebViewNavigationDelegate alloc] initWithOriginalDelegate:nil]);
    return result;
}
#endif

#if !TARGET_OS_TV
id initWithFrame_configuration(id self, SEL _cmd, CGRect frame, id configuration) {
    id result = NRMA__WKWebView_initWithFrame_configuration(self, _cmd, frame, configuration);
    NRMA__WKWebView_setNavigationDelegate(result, _cmd,  [[NRMAWKWebViewNavigationDelegate alloc] initWithOriginalDelegate:nil]);

    return result;
}
#endif
