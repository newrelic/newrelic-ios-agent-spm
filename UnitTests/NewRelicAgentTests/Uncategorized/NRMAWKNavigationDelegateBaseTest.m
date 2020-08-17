//
//  NRMAWKNavigationDelegateBaseTest.m
//  NewRelicAgent
//
//  Created by Austin Washington on 7/26/17.
//  Copyright © 2017 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "NRMAWKWebViewNavigationDelegate.h"
#import "NRTimer.h"
#import <WebKit/WebKit.h>

@interface NRWKNavigationDelegateBase ()
- (instancetype) initWithOriginalDelegate:(NSObject<WKNavigationDelegate>* __nullable __weak)delegate;
+ (NSURL*) navigationURL:(WKNavigation*) nav;
+ (NRTimer*) navigationTimer:(WKNavigation*) nav;
+ (void) navigation:(WKNavigation*)nav setURL:(NSURL*)url;
+ (void) navigation:(WKNavigation*)nav setTimer:(NRTimer*)timer;
@end

@interface NRMAWKNavigationDelegateDaseTest : XCTestCase <WKNavigationDelegate>
@property(strong) NRTimer* timer;
@property(strong) NSURL* url;
@property(strong) WKNavigation* web;
@property(strong) NRMAWKWebViewNavigationDelegate* navBase;

@end

@implementation NRMAWKNavigationDelegateDaseTest

- (void)setUp {
    [super setUp];
    self.navBase = [[NRMAWKWebViewNavigationDelegate alloc] initWithOriginalDelegate:self];
    self.web = [[WKNavigation alloc] init];
    self.url = [NSURL URLWithString: @"localhost"];
    self.timer = [[NRTimer alloc] init];
}


- (void)tearDown {
    [super tearDown];
}


- (void) testNilParameterPassing {
    @autoreleasepool {
        XCTAssertNoThrow([NRWKNavigationDelegateBase navigation:nil setURL:_url], @"");
        XCTAssertNil([NRWKNavigationDelegateBase navigationURL:_web]);
        
        XCTAssertNoThrow([NRWKNavigationDelegateBase navigation:nil setTimer:_timer], @"");
        XCTAssertNil([NRWKNavigationDelegateBase navigationTimer:_web]);
        //[NRWKNavigationDelegateBase navigationTimer:_web];
    }
}

- (void) testImpersonation {
    @autoreleasepool {
        XCTAssertTrue([self.navBase isKindOfClass:[self class]]);
        XCTAssertTrue([self.navBase isKindOfClass:[NRWKNavigationDelegateBase class]]);
    }
}

@end
