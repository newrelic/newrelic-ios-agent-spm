//
//  TestUICollectionViewInstrumentation.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 3/12/18.
//  Copyright © 2018 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OCMock/OCMock.h"
#import "NRMACollectionViewInstrumentation.h"
#import "NRMAFlags.h"
#import "NewRelicAgentInternal.h"


@interface StandardCollectionViewDelegate : NSObject <UICollectionViewDelegate, UICollectionViewDataSource>
@end

@implementation StandardCollectionViewDelegate
- (NSInteger) collectionView:(UICollectionView*)collectionView
      numberOfItemsInSection:(NSInteger)section {
    return 0;
}

- (__kindof UICollectionViewCell*) collectionView:(UICollectionView*)collectionView
                           cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    return nil;
}

- (void)  collectionView:(UICollectionView*)collectionView
didSelectItemAtIndexPath:(NSIndexPath*)indexPath {

}


@end

@interface TestUICollectionViewInstrumentation : XCTestCase
@property id mockFlags;
@property id mockNewRelicInternals;
@property UITableViewCell* cell;
@property BOOL truth;
@end

@implementation TestUICollectionViewInstrumentation

- (void)setUp {
    [super setUp];
    [NRMACollectionViewInstrumentation instrument];
    self.truth = YES;
    self.mockFlags = [OCMockObject mockForClass:[NRMAFlags class]];
    [[[[self.mockFlags stub] classMethod] andReturnValue:[NSValue value:&_truth withObjCType:@encode(BOOL)]] shouldEnableGestureInstrumentation];
    self.mockNewRelicInternals = [OCMockObject niceMockForClass:[NewRelicAgentInternal class]];
}

- (void)tearDown {
    [self.mockFlags stopMocking];
    [self.mockNewRelicInternals stopMocking];
    [NRMACollectionViewInstrumentation deinstrument];
    [super tearDown];
}

- (void) testTableView {

    StandardCollectionViewDelegate* delegate = [[StandardCollectionViewDelegate alloc] init];

    id mockDelegate = [OCMockObject partialMockForObject:delegate];

    [[[mockDelegate expect] andForwardToRealObject] collectionView:OCMOCK_ANY
                                      didSelectItemAtIndexPath:OCMOCK_ANY];

    [[self.mockNewRelicInternals expect] sharedInstance];


    UICollectionView* collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero
                                                          collectionViewLayout:[[UICollectionViewLayout alloc] init]];

    collectionView.delegate = mockDelegate;

    [mockDelegate collectionView:collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForRow:1
                                                                                 inSection:0]];

    [self.mockNewRelicInternals verify];
    [mockDelegate verify];

    [mockDelegate stopMocking];
}
@end
