//
//  NRMAAppTokenTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/19/18.
//  Copyright © 2018 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAAppToken.h"

@interface NRMAAppTokenTest : XCTestCase

@end

@implementation NRMAAppTokenTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRegionAware {
    NSString* regionAwareAppToken = @"eu01xxAAAABBBBCCCCDDDDEEEE11223344556677889900";

    NRMAAppToken* appToken = [[NRMAAppToken alloc] initWithApplicationToken:regionAwareAppToken];

    XCTAssertTrue([appToken.regionCode isEqualToString:@"eu01"]);
    XCTAssertTrue([appToken.value isEqualToString:regionAwareAppToken]);
}

- (void)testRegionAwareWithX {
    NSString* regionAwareAppToken = @"xeux01xxAAAABBBBCCCCDDDDEEEE11223344556677889900";

    NRMAAppToken* appToken = [[NRMAAppToken alloc] initWithApplicationToken:regionAwareAppToken];

    XCTAssertTrue([appToken.regionCode isEqualToString:@"xeu"]);
    XCTAssertTrue([appToken.value isEqualToString:regionAwareAppToken]);
}

- (void) testNoRegion {
    NSString* appTokenStr = @"AAAABBBBCCCCDDDDEEEE11223344556677889900";

    NRMAAppToken* appToken = [[NRMAAppToken alloc] initWithApplicationToken:appTokenStr];

    XCTAssertEqual(appToken.regionCode.length, 0);
    XCTAssertTrue([appToken.value isEqualToString:appTokenStr]);
}

@end
