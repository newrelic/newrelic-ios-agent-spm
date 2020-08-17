//
//  Copyright © 2018 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAUserActionBuilder.h"
#import "NRConstants.h"

@interface NRMAUserActionBuilderTest : XCTestCase

@end

@implementation NRMAUserActionBuilderTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCanBuildForegroundGestures {

    NRMAUserAction* fgGesture = [NRMAUserActionBuilder buildWithBlock:^(NRMAUserActionBuilder *builder) {
        [builder withActionType:kNRMAUserActionAppLaunch];
    }];

    XCTAssertNotNil(fgGesture);
    XCTAssertEqual(kNRMAUserActionAppLaunch, fgGesture.actionType);
    XCTAssertNotNil(fgGesture.timeCreated);
    XCTAssertTrue([@"ApplicationWillEnterForeground" isEqualToString: fgGesture.associatedMethod]);
    XCTAssertTrue([@"AppDelegate" isEqualToString:fgGesture.associatedClass]);
    XCTAssertTrue([@"" isEqualToString:fgGesture.elementLabel]);
    XCTAssertTrue([@"" isEqualToString:fgGesture.accessibilityId]);
    XCTAssertTrue([@"" isEqualToString:fgGesture.elementFrame]);
    XCTAssertTrue([@"" isEqualToString:fgGesture.interactionCoordinates]);
}

- (void)testCanBuildBackgroundGestures {
    NRMAUserAction* bgGesture = [NRMAUserActionBuilder buildWithBlock:^(NRMAUserActionBuilder *builder) {
        [builder withActionType:kNRMAUserActionAppBackground];
    }];

    XCTAssertNotNil(bgGesture);
    XCTAssertEqual(kNRMAUserActionAppBackground, bgGesture.actionType);
    XCTAssertNotNil(bgGesture.timeCreated);
    XCTAssertTrue([@"ApplicationWillEnterBackground" isEqualToString: bgGesture.associatedMethod]);
    XCTAssertTrue([@"AppDelegate" isEqualToString:bgGesture.associatedClass]);
    XCTAssertTrue([@"" isEqualToString:bgGesture.elementLabel]);
    XCTAssertTrue([@"" isEqualToString:bgGesture.accessibilityId]);
    XCTAssertTrue([@"" isEqualToString:bgGesture.elementFrame]);
    XCTAssertTrue([@"" isEqualToString:bgGesture.interactionCoordinates]);
}

-(void)testCallingBuildWithoutSettingRequiredDataReturnsNil {
    // "Required Data" = Type, associated method and associated class.
    NRMAUserAction* noData = [NRMAUserActionBuilder buildWithBlock:^(NRMAUserActionBuilder *builder) {
    }];
    NRMAUserAction* noType = [NRMAUserActionBuilder buildWithBlock:^(NRMAUserActionBuilder *builder) {
        [builder withActionType:@""];
    }];
    NRMAUserAction* emptyMethod = [NRMAUserActionBuilder buildWithBlock:^(NRMAUserActionBuilder *builder) {
        [builder withActionType:@"SomeActionTypeHere"];
        [builder fromMethod:@""];
        [builder fromClass:@"Someclass"];
    }];
    NRMAUserAction* emptyClass= [NRMAUserActionBuilder buildWithBlock:^(NRMAUserActionBuilder *builder) {
        [builder withActionType:@"SomeActionTypeHere"];
        [builder fromMethod:@"someMethod"];
        [builder fromClass:@""];
    }];
    XCTAssertNil(noData);
    XCTAssertNil(noType);
    XCTAssertNil(emptyMethod);
    XCTAssertNil(emptyClass);
}

@end

