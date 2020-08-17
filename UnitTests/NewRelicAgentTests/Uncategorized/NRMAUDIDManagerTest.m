//
//  NRMAUDIDManagerTest.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 12/9/15.
//  Copyright © 2015 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAUDIDManager.h"
#import "NRMAUUIDStore.h"
#import "NRConstants.h"
#import "NRMAFlags.h"
#import <OCMock/OCMock.h>


@interface NRMAUDIDManager ()
+ (NRMAUUIDStore*) secureUDIDStore;
+ (NRMAUUIDStore*) identifierForVendorStore;
+ (void) setUDID:(NSString*)udid;

+ (NSString*) getSystemIdentifier;
+ (NSString*) saltValue;
@end

@interface NRMAUDIDManagerTest : XCTestCase
@property(strong) NSString* vendorId;
@property(strong) NSString* storedVendorID;


@property(strong) id mockVendorStore;
@property(strong) id mockUIDevice;
@property(strong) id mockNSUUID;

@property(strong) id returnValue;
@end

@implementation NRMAUDIDManagerTest

- (void)setUp {
    [super setUp];
    [NRMAUDIDManager setUDID:nil];
}

- (void) testUUIDSalt {
    self.vendorId = @"ABCDEF123456789";
    NSString* salt = @"salt1";
    [self subSetup];
    id mockFlags = [OCMockObject mockForClass:[NRMAFlags class]];
    id mockNRMAUDIDManager = [OCMockObject niceMockForClass:[NRMAUDIDManager class]];
    [[[[mockNRMAUDIDManager stub] classMethod] andReturn:salt] saltValue];

    BOOL returnValue = true;
    [[[[mockFlags stub] classMethod] andReturnValue:[NSValue value:&returnValue withObjCType:"c"]] shouldSaltDeviceUUID];

    NSString* udid = [NRMAUDIDManager getSystemIdentifier];

    XCTAssertNotEqual(udid, self.vendorId);

    salt = @"salt2";
    
    [mockNRMAUDIDManager stopMocking];
    mockNRMAUDIDManager = [OCMockObject niceMockForClass:[NRMAUDIDManager class]];
    [[[[mockNRMAUDIDManager stub] classMethod] andReturn:salt] saltValue];

    
    NSString* udid2 = [NRMAUDIDManager getSystemIdentifier];
    
    XCTAssertNotEqual(udid, udid2);
    
    [mockFlags stopMocking];
    [mockNRMAUDIDManager stopMocking];
    [self subShutdown];

}

- (void) subSetup {
    self.mockVendorStore = [OCMockObject partialMockForObject:[NRMAUDIDManager identifierForVendorStore]];
    self.mockUIDevice = [OCMockObject niceMockForClass:[UIDevice class]];
    self.mockNSUUID = [OCMockObject partialMockForObject:[NSUUID new]];



    [[[self.mockVendorStore stub] andReturn:self.storedVendorID] storedUUID];

    [[[[self.mockUIDevice stub] classMethod] andReturn:self.mockUIDevice] currentDevice];

    [[[self.mockNSUUID stub] andReturn:self.vendorId] UUIDString];

    [[[self.mockUIDevice stub] andReturn:self.mockNSUUID] identifierForVendor];
}

- (void) subShutdown {
    [self.mockVendorStore stopMocking];
    [self.mockUIDevice stopMocking];
    [self.mockNSUUID  stopMocking];
}

- (void)tearDown {
    [NRMAUDIDManager setUDID:nil];
    [super tearDown];
}

- (void) testNoSavedStores {
    self.vendorId = @"1";
    self.storedVendorID = nil;


    __block BOOL didReceiveNotification = NO;
    [self subSetup];
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:kNRMADidGenerateNewUDIDNotification object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      XCTAssertEqualObjects(note.userInfo[@"UDID"],self.vendorId);
                                                      didReceiveNotification = YES;
                                                  }];
    [[self.mockVendorStore expect] storeUUID:self.vendorId];
    XCTAssertEqualObjects(self.vendorId, [NRMAUDIDManager UDID]);
    XCTAssertNoThrow([self.mockVendorStore verify]);

    while (CFRunLoopGetCurrent() && !didReceiveNotification) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:observer];
    [self subShutdown];
}


- (void) testNoSavedStoresAndVendorIDUnavailable {
    self.vendorId = nil;
    self.storedVendorID = nil;

    [self subSetup];

    __block BOOL didReceiveNotification = NO;
     id observer = [[NSNotificationCenter defaultCenter] addObserverForName:kNRMADidGenerateNewUDIDNotification object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      XCTAssertNotNil(note.userInfo[@"UDID"]);
                                                      didReceiveNotification = YES;
                                                  }];

    [[self.mockVendorStore expect] storeUUID:OCMOCK_ANY];
    XCTAssertNotNil([NRMAUDIDManager UDID]);
    XCTAssertThrows([self.mockVendorStore verify]);

    while (CFRunLoopGetCurrent() && !didReceiveNotification) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:observer];
    [self subShutdown];
}

- (void) testHasUDID {
    self.vendorId = @"1";
    self.storedVendorID = @"1";

    [self subSetup];
    [[self.mockVendorStore expect] storeUUID:OCMOCK_ANY];
    XCTAssertThrows([self.mockVendorStore verify]);
    [self subShutdown];
}

- (void) testNoVendorId {
    self.vendorId = nil;
    self.storedVendorID = nil;
    [self subSetup];
    [[self.mockVendorStore expect] storeUUID:OCMOCK_ANY];
    XCTAssertNotNil([NRMAUDIDManager UDID]);
    XCTAssertNotEqual(@"", [NRMAUDIDManager UDID]);
    XCTAssertThrows([self.mockVendorStore verify]);
    [self subShutdown];
}

- (void) testVendorNoStore {
    self.vendorId = @"2";
    self.storedVendorID = nil;

    [self subSetup];
    [[self.mockVendorStore expect] storeUUID:self.vendorId];

    XCTAssertEqualObjects(@"2", [NRMAUDIDManager UDID]);
    XCTAssertNoThrow([self.mockVendorStore verify]);

    [self subShutdown];
}

- (void) testSecureUDIDVendorIdChanged {

    self.vendorId = @"50";
    self.storedVendorID = @"49";
    
    [self subSetup];

    __block BOOL didReceiveNotification = NO;
     id observer = [[NSNotificationCenter defaultCenter] addObserverForName:kNRMADidGenerateNewUDIDNotification object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      XCTAssertEqualObjects(note.userInfo[@"UDID"],self.vendorId);
                                                      didReceiveNotification = YES;
                                                  }];

    [[self.mockVendorStore expect] storeUUID:self.vendorId];
    XCTAssertEqualObjects(self.vendorId, [NRMAUDIDManager UDID]);
    XCTAssertNoThrow([self.mockVendorStore verify]);

    while (CFRunLoopGetCurrent() && !didReceiveNotification) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:observer];
    [self subShutdown];
}

- (void) testAgentDidUpgrade {

    self.vendorId = @"50";
    self.storedVendorID = @"20";
    
    [self subSetup];
    XCTAssertEqualObjects(self.storedVendorID,[self.mockVendorStore storedUUID]);
    [[self.mockVendorStore expect] storeUUID:self.vendorId];
    XCTAssertEqualObjects(self.vendorId, [NRMAUDIDManager UDID]);
    XCTAssertNoThrow([self.mockVendorStore verify]);
    [self subShutdown];
}

- (void) testVendorIDUpgrade {

    self.vendorId = @"50";
    self.storedVendorID = @"50";

    [self subSetup];
    //validates stores aren't updated
    [[self.mockVendorStore expect] storeUUID:OCMOCK_ANY];
    XCTAssertEqualObjects(self.storedVendorID, [NRMAUDIDManager UDID]);
    XCTAssertThrows([self.mockVendorStore verify]);
    [self subShutdown];

    //reset in memory udid
    [NRMAUDIDManager setUDID:nil];

   self.vendorId = @"51";

    [self subSetup];
    [[self.mockVendorStore expect] storeUUID:self.vendorId];
    XCTAssertEqualObjects(self.vendorId, [NRMAUDIDManager UDID]);
    XCTAssertNoThrow([self.mockVendorStore verify]);
    [self subShutdown];

}


- (void) testSecureUDIDToVendorIDUpgrade
{
    self.vendorId = @"50";
    self.storedVendorID = @"50";

    [self subSetup];
    [[self.mockVendorStore expect] storeUUID:OCMOCK_ANY];
    XCTAssertThrows([self.mockVendorStore verify]);
    [self subShutdown];

    //reset in memory udid
    [NRMAUDIDManager setUDID:nil];

    self.vendorId = @"51";

    [self subSetup];

    __block BOOL didReceiveNotification = NO;
     id observer = [[NSNotificationCenter defaultCenter] addObserverForName:kNRMADidGenerateNewUDIDNotification object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      XCTAssertEqualObjects(note.userInfo[@"UDID"],self.vendorId);
                                                      didReceiveNotification = YES;
                                                  }];

    [[self.mockVendorStore expect] storeUUID:self.vendorId];
    XCTAssertEqualObjects(self.vendorId, [NRMAUDIDManager UDID]);
    XCTAssertNoThrow([self.mockVendorStore verify]);

    while (CFRunLoopGetCurrent() && !didReceiveNotification) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:observer];

    [self subShutdown];
}

- (void) testSecureUDIDNoVendorID
{
    self.vendorId = nil;
    self.storedVendorID = nil;

    [self subSetup];
    [[self.mockVendorStore expect] storeUUID:OCMOCK_ANY];
    XCTAssertThrows([self.mockVendorStore verify]);
    [self subShutdown];
}


- (void) testSecureUDIDVendorID
{
    self.vendorId = @"1";
    self.storedVendorID = nil;

    [self subSetup];
    [[self.mockVendorStore expect] storeUUID:self.vendorId];
    XCTAssertEqual(self.vendorId,[NRMAUDIDManager UDID]);
    XCTAssertNoThrow([self.mockVendorStore verify]);
    [self subShutdown];
}
@end

