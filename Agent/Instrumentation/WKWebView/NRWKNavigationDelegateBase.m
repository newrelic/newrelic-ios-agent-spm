//
//  NRMAWKWebViewDelegateBase.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/5/17.
//  Copyright © 2017 New Relic. All rights reserved.
//

#import "NRWKNavigationDelegateBase.h"
#import "NRMANetworkFacade.h"
#import <objc/runtime.h>
#import "NRTimer.h"

#define kNRWKTimerAssocObject @"com.NewRelic.WKNavigation.Timer"
#define kNRWKURLAssocObject @"com.NewRelic.WKNavigation.URL"

@class WKWebView, WKNavigation, WKNavigationAction, WKNavigationResponse;
@protocol WKNavigationDelegate;

@implementation NRWKNavigationDelegateBase

- (instancetype) initWithOriginalDelegate:(NSObject<WKNavigationDelegate>* __nullable __weak)delegate {
    self = [super init];
    if (self) {
        _realDelegate = delegate;
    }
    return self;
}

#pragma mark - WKNavigationDelegate methods

//- (void)    webView:(WKWebView*)webView
//didCommitNavigation:(WKNavigation*)navigation
//{
//
//}

- (void)              webView:(WKWebView*)webView
didStartProvisionalNavigation:(WKNavigation*)navigation {
    //record network details
    [NRWKNavigationDelegateBase navigation:navigation setTimer:[NRTimer new]];

    NSURL* url = nil;
    Method m = class_getInstanceMethod(objc_getClass("WKWebView"), @selector(URL));

    if (m != NULL) {
        url = ((NSURL*(*)(id,SEL))(IMP)method_getImplementation(m))(webView,@selector(URL));;
    }

    [NRWKNavigationDelegateBase navigation:navigation setURL:url];
    if ([self.realDelegate respondsToSelector:_cmd]) {
        [self.realDelegate performSelector:@selector(webView:didStartProvisionalNavigation:)
                                withObject:webView
                                withObject:navigation];
    }
}

- (void)    webView:(WKWebView*)webView
didFinishNavigation:(WKNavigation*)navigation
{

    //record network details

    NRTimer* timer = [NRWKNavigationDelegateBase navigationTimer:navigation];
    NSURL* url = [NRWKNavigationDelegateBase navigationURL:navigation];
    if (timer) {

        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"GET"];

        NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                                  statusCode:200
                                                                 HTTPVersion:nil
                                                                headerFields:nil];

        [NRMANetworkFacade noticeNetworkRequest:request
                                       response:response
                                      withTimer:timer
                                      bytesSent:0
                                  bytesReceived:0
                                   responseData:nil
                                         params:nil];
    }


    if ([self.realDelegate respondsToSelector:_cmd]) {
        [self.realDelegate performSelector:@selector(webView:didFinishNavigation:)
                                withObject:webView
                                withObject:navigation];
    }

}

- (void)             webView:(WKWebView*)webView
didFailProvisionalNavigation:(WKNavigation*)navigation
                   withError:(NSError*)error
{
    NRTimer* timer = [NRWKNavigationDelegateBase navigationTimer:navigation];

    NSURL* url = [NRWKNavigationDelegateBase navigationURL:navigation];

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];

    [NRMANetworkFacade noticeNetworkFailure:request
                                  withTimer:timer
                                  withError:error];

    if ([self.realDelegate respondsToSelector:_cmd]) {
        Method m = class_getInstanceMethod([self.realDelegate class], _cmd);
        ((void(*)(id,SEL,id,id,id))method_getImplementation(m))(self.realDelegate,_cmd, webView,navigation,error);
    }
}



- (void)  webView:(WKWebView*)webView
didFailNavigation:(WKNavigation*)navigation
        withError:(NSError*)error
{

    //record network details
    NRTimer* timer = [NRWKNavigationDelegateBase navigationTimer:navigation];

    NSURL* url = [NRWKNavigationDelegateBase navigationURL:navigation];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];

    [NRMANetworkFacade noticeNetworkFailure:request
                                  withTimer:timer
                                  withError:error];
    
    if ([self.realDelegate respondsToSelector:_cmd]) {
        Method m = class_getInstanceMethod([self.realDelegate class], _cmd);
        ((void(*)(id,SEL,id,id,id))method_getImplementation(m))(self.realDelegate,_cmd, webView,navigation,error);
    }
}


+ (NSURL*) navigationURL:(WKNavigation*)nav
{
    if(nav == nil) return nil;
    
    return objc_getAssociatedObject(nav, kNRWKURLAssocObject);
}

+ (void) navigation:(WKNavigation*)nav setURL:(NSURL*)url {
    if(nav == nil) return;
    
    objc_AssociationPolicy assocPolicy = OBJC_ASSOCIATION_RETAIN;
    if (url == nil) {
        assocPolicy = OBJC_ASSOCIATION_ASSIGN;
    }
    objc_setAssociatedObject(nav, kNRWKURLAssocObject, url, assocPolicy);
}

+ (NRTimer*) navigationTimer:(WKNavigation*) nav
{
    if(nav == nil) return nil;
    
    return objc_getAssociatedObject(nav, kNRWKTimerAssocObject);
}

+ (void) navigation:(WKNavigation*)nav setTimer:(NRTimer*)timer {
    if(nav == nil) return;
    
    objc_AssociationPolicy assocPolicy = OBJC_ASSOCIATION_RETAIN;
    if (timer == nil) {
        assocPolicy = OBJC_ASSOCIATION_ASSIGN;
    }
    objc_setAssociatedObject(nav, kNRWKTimerAssocObject, timer, assocPolicy);
}
@end
