//
//  NRMAUUIDStoreTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 12/10/15.
//  Copyright © 2015 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAUUIDStore.h"

@interface NRMAUUIDStore ()
- (NSString*) storePath;
- (BOOL) storeExists;
@end

@interface NRMAUUIDStoreTests : XCTestCase
@property(strong) NSString* filename;
@property(strong) NRMAUUIDStore* store;
@end

@implementation NRMAUUIDStoreTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.filename = @"myFile";
    self.store = [[NRMAUUIDStore alloc] initWithFilename:self.filename];
    [[NSFileManager defaultManager] removeItemAtPath:[[self.store storePath] stringByAppendingFormat:@"/%@",self.filename]
                                               error:nil];
}

- (void)tearDown {

    [[NSFileManager defaultManager] removeItemAtPath:[[self.store storePath] stringByAppendingFormat:@"/%@",self.filename]
                                               error:nil];
    [super tearDown];
}


- (void) testCreateFile {
    NSString* UUID = @"Hello, world.";
    XCTAssertFalse([self.store storeExists]);
    XCTAssertTrue([self.store storeUUID:UUID]);
    XCTAssertTrue([self.store storeExists]);
    XCTAssertEqualObjects([self.store storedUUID], UUID);
}

- (void) testChangeUUID {

    NSString* UUID = @"Hello, world.";
    [self.store storeUUID:UUID];
    [self.store storeUUID:@"asdf"];
    XCTAssertEqualObjects([self.store storedUUID],@"asdf");

}
- (void) testLoadStore {
    NSString* UUID = @"Hello, world.";
    [self.store storeUUID:UUID];
    self.store = [[NRMAUUIDStore alloc] initWithFilename:self.filename];
    XCTAssertEqualObjects([self.store storedUUID],UUID);
}


@end
