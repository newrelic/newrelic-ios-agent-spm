//
//  NRMAWKWebViewTests.m
//  NRInstrumentationTests
//
//  Created by Bryce Buchanan on 7/8/19.
//  Copyright © 2019 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RootTests.h"
#import "NRMAWKWebViewInstrumentation.h"
#import "NRMAWKWebViewNavigationDelegate.h"
#import <WebKit/WebKit.h>
#import <OCMock/OCMock.h>

extern id (*NRMA__WKWebView_navigationDelegate)(id self,
                                         SEL _cmd);
@interface NRMAWKWebViewTests : RootTests
@property(retain) WKWebView* webView;
@end


@interface Delegate : NSObject<WKNavigationDelegate>
@end

@implementation Delegate
@end

@implementation NRMAWKWebViewTests
- (void)setUp {
    [NRMAWKWebViewInstrumentation instrument];
   
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [NRMAWKWebViewInstrumentation deinstrument];
}

- (void)testReleaseOfInstrumentedWebViewDelegateObject {
    
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[WKWebViewConfiguration new]];

    //get the true navigation delegate (NRMAWebViewNavigationDelegate), rather than our redirected instrumented one
   id navDelegate = NRMA__WKWebView_navigationDelegate(self.webView,@selector(navigationDelegate));
    
    XCTAssertEqual(2, [navDelegate retainCount]);
    
    self.webView.navigationDelegate = nil;

    XCTAssertEqual(1, [navDelegate retainCount]); // we see the nav delegate's retain count is decreased by 1 after it is no longer used internally.
    
}


@end
