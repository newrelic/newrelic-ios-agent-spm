//
//  NRMAInternalTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 12/13/17.
//  Copyright © 2017 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "NRMANetworkFacade.h"
#import "NRMAHarvestController.h"


@interface NRMANetworkFacade ()
+ (int) insightsAttributeSizeLimit;
+ (int) responseBodyCaptureSizeLimit;
+ (NSString*) generateResponseBody:(NSData*)responseBody  sizeLimit:(int)sizeLimit;
@end
@interface NRMAInternalTests : XCTestCase
@property(strong) id mockInternal;
@end


@implementation NRMAInternalTests

- (void)setUp {
    [super setUp];
    self.mockInternal = [OCMockObject mockForClass:[NRMAHarvestController class]];
    [[[[self.mockInternal stub] classMethod] andReturn:[NRMAHarvesterConfiguration defaultHarvesterConfiguration]] configuration];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [self.mockInternal stopMocking];
    [super tearDown];
}

- (void)testResponseBodySizes {
    XCTAssertEqual(4096,[NRMANetworkFacade insightsAttributeSizeLimit]);
    XCTAssertEqual(2048,[NRMANetworkFacade responseBodyCaptureSizeLimit]);
}

- (void) testResponseBodyTruc {
    NSData* data = [@"Hello, world!" dataUsingEncoding:NSUTF8StringEncoding];
    NSString* truncatedString = [NRMANetworkFacade generateResponseBody:data sizeLimit:5];
    XCTAssertTrue([@"Hello" isEqualToString:truncatedString]);

}

@end
