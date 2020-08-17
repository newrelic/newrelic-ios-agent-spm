//
//  TestUITableViewInstrumentation.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 3/12/18.
//  Copyright © 2018 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "NRMATableViewIntrumentation.h"
#import "NewRelicAgentInternal.h"
#import "NRMAFlags.h"

@interface StandardTableViewDelegate : NSObject <UITableViewDelegate, UITableViewDataSource>
@end

@implementation StandardTableViewDelegate
- (void)      tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath {

}


- (NSInteger) tableView:(UITableView*)tableView
  numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell*) tableView:(UITableView*)tableView
         cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    return nil;
}


@end


@interface TestUITableViewInstrumentation : XCTestCase

@property id mockFlags;
@property id mockNewRelicInternals;
@property UITableViewCell* cell;
@property BOOL truth;

@end


@implementation TestUITableViewInstrumentation


- (void)setUp {
    [super setUp];
    [NRMATableViewIntrumentation instrument];
    self.truth = YES;
    self.mockFlags = [OCMockObject mockForClass:[NRMAFlags class]];
    [[[[self.mockFlags stub] classMethod] andReturnValue:[NSValue value:&_truth withObjCType:@encode(BOOL)]] shouldEnableGestureInstrumentation];
    self.mockNewRelicInternals = [OCMockObject niceMockForClass:[NewRelicAgentInternal class]];
}

- (void)tearDown {
    [self.mockFlags stopMocking];
    [self.mockNewRelicInternals stopMocking];
    [NRMATableViewIntrumentation deinstrument];
    [super tearDown];
}

- (void) testTableView {

    StandardTableViewDelegate* delegate = [[StandardTableViewDelegate alloc] init];

    id mockDelegate = [OCMockObject partialMockForObject:delegate];

    [[[mockDelegate expect] andForwardToRealObject] tableView:OCMOCK_ANY
             didSelectRowAtIndexPath:OCMOCK_ANY];

    [[self.mockNewRelicInternals expect] sharedInstance];


    UITableView* tableView = [[UITableView alloc] initWithFrame:CGRectZero
                                                          style:UITableViewStylePlain];

    tableView.delegate = mockDelegate;

    [mockDelegate tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:1
                                                                                 inSection:0]];

    [self.mockNewRelicInternals verify];
    [mockDelegate verify];

    [mockDelegate stopMocking];
}



@end
