//
//  NRMABase64EncoderTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/29/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMABase64.h"

@interface NRMABase64 ()
+ (int) generateIndexForFirstBase64Char:(uint8_t)firstByte;
+ (int) generateIndexForSecondBase64Char:(uint8_t)firstByte secondByte:(uint8_t)secondbyte;
+ (int) generateIndexForThirdBase64Char:(uint8_t)secondByte thirdByte:(uint8_t)thirdByte;
+ (int) generateindexForFourthBase64Char:(uint8_t)thirdByte;
+ (const char*) base64LookupTable;
@end

@interface NRMABase64EncoderTests : XCTestCase

@end

@implementation NRMABase64EncoderTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testOneByte
{
    NSString* str = @"a";
    NSString* expectedBase64Str = @"YQ==";
    NSString* base64String = [NRMABase64 encodeFromData:[str dataUsingEncoding:NSUTF8StringEncoding]];

    XCTAssertTrue([base64String isEqualToString:expectedBase64Str], @"base64 encoded incorrectly: should be %@ was %@",expectedBase64Str,base64String);
}

- (void)testTwoByte
{
    NSString* str = @"Zg";
    NSString* expectedBase64Str = @"Wmc=";

    NSString* base64String = [NRMABase64 encodeFromData:[str dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertTrue([base64String isEqualToString:expectedBase64Str], @"base64 encoded incorrectly: should be %@ was %@",expectedBase64Str,base64String);
}

- (void) testThreeByte
{
    NSString* str = @"q0m";
    NSString* expectedBase64Str = @"cTBt";
    NSString* base64String = [NRMABase64 encodeFromData:[str dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertTrue([base64String isEqualToString:expectedBase64Str], @"base64 encoded incorrectly: should be %@ was %@",expectedBase64Str,base64String);
}

- (void) testLongString
{
    NSString* str = @"Now, Maria Helena Teresa Fafila Servanda Jimena Mansuara Paterna Domenga Gelvira Placia Sendina Belita Eufemia Columba Gontina Aldonza Mafalda Cristina Tegrida de Falcon has sailed through the ages, collecting names for herself and a crew from her past, present, and future, all with the same thirst for adventure and greed for the riches of everywhere . . . and everywhen!";

    NSString* expectedBase64Str = @"Tm93LCBNYXJpYSBIZWxlbmEgVGVyZXNhIEZhZmlsYSBTZXJ2YW5kYSBKaW1lbmEgTWFuc3VhcmEgUGF0ZXJuYSBEb21lbmdhIEdlbHZpcmEgUGxhY2lhIFNlbmRpbmEgQmVsaXRhIEV1ZmVtaWEgQ29sdW1iYSBHb250aW5hIEFsZG9uemEgTWFmYWxkYSBDcmlzdGluYSBUZWdyaWRhIGRlIEZhbGNvbiBoYXMgc2FpbGVkIHRocm91Z2ggdGhlIGFnZXMsIGNvbGxlY3RpbmcgbmFtZXMgZm9yIGhlcnNlbGYgYW5kIGEgY3JldyBmcm9tIGhlciBwYXN0LCBwcmVzZW50LCBhbmQgZnV0dXJlLCBhbGwgd2l0aCB0aGUgc2FtZSB0aGlyc3QgZm9yIGFkdmVudHVyZSBhbmQgZ3JlZWQgZm9yIHRoZSByaWNoZXMgb2YgZXZlcnl3aGVyZSAuIC4gLiBhbmQgZXZlcnl3aGVuIQ==";

    NSString* base64String = [NRMABase64 encodeFromData:[str dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertTrue([base64String isEqualToString:expectedBase64Str], @"base64 encoded incorrectly: should be %@ was %@",expectedBase64Str,base64String);
}

- (void) testBuffaloString
{
    NSString* str = @"Buffalo buffalo Buffalo buffalo buffalo buffalo Buffalo buffalo";
    NSString* expectedBase64Str = @"QnVmZmFsbyBidWZmYWxvIEJ1ZmZhbG8gYnVmZmFsbyBidWZmYWxvIGJ1ZmZhbG8gQnVmZmFsbyBidWZmYWxv";
    NSString* base64String = [NRMABase64 encodeFromData:[str dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertTrue([base64String isEqualToString:expectedBase64Str], @"base64 encoded incorrectly: should be %@ was %@",expectedBase64Str,base64String);
}
- (void) testUTF8Str
{
    NSString* str = @"𠜎 𠜱 𠝹 𠱓 𠱸 𠲖 𠳏 𠳕 𠴕 𠵼 𠵿 𠸎 𠸏 𠹷 𠺝 𠺢 𠻗 𠻹 𠻺 𠼭 𠼮 𠽌 𠾴 𠾼 𠿪 𡁜 𡁯 𡁵 𡁶 𡁻 𡃁 𡃉 𡇙 𢃇 𢞵 𢫕 𢭃 𢯊 𢱑 𢱕 𢳂 𢴈 𢵌 𢵧 𢺳 𣲷 𤓓 𤶸 𤷪 𥄫 𦉘 𦟌 𦧲 𦧺 𧨾 𨅝 𨈇 𨋢 𨳊 𨳍 𨳒 𩶘";
    NSString* expectedBase64Str = @"8KCcjiDwoJyxIPCgnbkg8KCxkyDwoLG4IPCgspYg8KCzjyDwoLOVIPCgtJUg8KC1vCDwoLW/IPCguI4g8KC4jyDwoLm3IPCgup0g8KC6oiDwoLuXIPCgu7kg8KC7uiDwoLytIPCgvK4g8KC9jCDwoL60IPCgvrwg8KC/qiDwoYGcIPChga8g8KGBtSDwoYG2IPChgbsg8KGDgSDwoYOJIPChh5kg8KKDhyDwop61IPCiq5Ug8KKtgyDwoq+KIPCisZEg8KKxlSDworOCIPCitIgg8KK1jCDworWnIPCiurMg8KOytyDwpJOTIPCktrgg8KS3qiDwpYSrIPCmiZgg8KafjCDwpqeyIPCmp7og8KeoviDwqIWdIPCoiIcg8KiLoiDwqLOKIPCos40g8KizkiDwqbaY";

    NSString* base64String = [NRMABase64 encodeFromData:[str dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertTrue([base64String isEqualToString:expectedBase64Str], @"base64 encoded incorrectly: should be %@ was %@",expectedBase64Str,base64String);
}

- (void) testBase64LookupTable
{
    XCTAssertEqual(strlen([NRMABase64 base64LookupTable]), (size_t)64, @"the lookup table should be 64 bytes long!");
}


- (void) testFirstBitShifter
{
    unsigned long long badData = ~0;
    unsigned int index = [NRMABase64 generateIndexForFirstBase64Char:badData];
    XCTAssertTrue(index < 64, @"index should be less than 64, the size of the base64 char array");
    XCTAssertTrue(index >= 0, @"index should not be negative");
}


- (void) testSecondBitShifter
{
    unsigned long long badData = ~0;
    unsigned int index = [NRMABase64 generateIndexForSecondBase64Char:badData secondByte:badData];
    XCTAssertTrue(index < 64, @"index should be less than 64, the size of the base64 char array");
    XCTAssertTrue(index >= 0, @"index should not be negative");
}

- (void) testThirdBitShifter
{
    unsigned long long badData = ~0;
    unsigned int index = [NRMABase64 generateIndexForThirdBase64Char:badData thirdByte:badData];
    XCTAssertTrue(index < 64, @"index should be less than 64, the size of the base64 char array");
    XCTAssertTrue(index >= 0, @"index should not be negative");
}

- (void) testFourthBitShifter
{
    unsigned long long badData = ~0;
    unsigned int index = [NRMABase64 generateindexForFourthBase64Char:badData];
    XCTAssertTrue(index < 64, @"index should be less than 64, the size of the base64 char array");
    XCTAssertTrue(index >= 0, @"index should not be negative");
}
@end
