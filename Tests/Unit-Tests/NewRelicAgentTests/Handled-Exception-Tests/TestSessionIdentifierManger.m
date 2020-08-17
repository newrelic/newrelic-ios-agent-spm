//
//  TestSessionIdentifierManger.m
//  NewRelic
//
//  Created by Bryce Buchanan on 7/24/17.
//  Copyright (c) 2017 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMASessionIdentifierManager.h"

@interface NRMASessionIdentifierManager ()
+ (void) purge;
- (void) setIdentifier:(NSString*)identifier;
@end

@interface TestSessionIdentifierManger : XCTestCase

@end

@implementation TestSessionIdentifierManger

- (void)setUp {
    [super setUp];
    [NRMASessionIdentifierManager purge];
}

- (void)tearDown {
    [NRMASessionIdentifierManager purge];
    [super tearDown];
}

- (void)testPersistentIdentifier {
    NRMASessionIdentifierManager* manager = [[NRMASessionIdentifierManager alloc] init];

    NSString* identifier = [manager sessionIdentifier];

    XCTAssertNotNil(identifier);

    NRMASessionIdentifierManager* manager2 = [[NRMASessionIdentifierManager alloc] init];

    XCTAssertEqualObjects(identifier, [manager2 sessionIdentifier]);
}


- (void) testLocal {
    NSString* value = @"MySessionIdentifier";
    NRMASessionIdentifierManager* manager = [[NRMASessionIdentifierManager alloc] init];
    [manager setIdentifier:value];
    XCTAssertTrue([manager.sessionIdentifier isEqualToString:value]);
}


@end
