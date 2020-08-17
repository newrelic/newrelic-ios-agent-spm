//
//  NRMAAgentTestBase.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/26/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OCMock/OCMock.h"
#import "Public/NRLogger.h"
#import "NRTestConstants.h"
#import "NRAgentTestBase.h"
#import "NRMAMethodSwizzling.h"
#import "NRMAHarvestController.h"
#import <objc/runtime.h> 

id (*NRMA__NSBundle_mainBundle)(id, SEL);
static id mock;
static NSMutableDictionary* _fakeInfoDictionary;

static NSBundle* overrideBundleBizniz(id self, SEL _cmd) {
    if (!mock) {
        NSBundle* bundle = nil;
        bundle = NRMA__NSBundle_mainBundle(self, _cmd);
        mock = [OCMockObject partialMockForObject: bundle];
        [[[mock stub] andReturn:_fakeInfoDictionary] infoDictionary];
        [[[mock stub] andReturn:@"com.test"] bundleIdentifier];
    }
    return mock;
}

@implementation NRMAAgentTestBase

+ (NSMutableDictionary*) fakeInfoDictionary
{
    return _fakeInfoDictionary;
}

- (void)setUp
{
    [super setUp];

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _fakeInfoDictionary = [NSMutableDictionary dictionary];
        [_fakeInfoDictionary setObject:@"1.0" forKey:@"CFBundleShortVersionString"];
        [_fakeInfoDictionary setObject:@"123" forKey:@"CFBundleVersion"];
        [_fakeInfoDictionary setObject:@"test" forKey:@"CFBundleExecutable"];

        id clazz = objc_getClass("NSBundle");
        if (clazz) {
            if (NRMA__NSBundle_mainBundle == NULL) {
                NRMA__NSBundle_mainBundle = NRMAReplaceClassMethod(clazz, @selector(mainBundle), (IMP)overrideBundleBizniz);
            }
        }

    });

    return;
}

- (void)tearDown
{
    [super tearDown];
}

@end
