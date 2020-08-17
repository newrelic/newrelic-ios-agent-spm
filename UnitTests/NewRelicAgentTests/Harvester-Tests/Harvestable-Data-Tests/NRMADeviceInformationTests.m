//
//  NRMADeviceInformationTests.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/11/16.
//  Copyright © 2016 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMADeviceInformation.h"
#import "NRConstants.h"
#import <Analytics/Constants.hpp>
#import "NewRelicInternalUtils.h"
@interface NRMADeviceInformationTests : XCTestCase

@end

@implementation NRMADeviceInformationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testInterface {
    NRMADeviceInformation* devInfo = [[NRMADeviceInformation alloc] init];
    XCTAssertNoThrow([devInfo platform]);
    XCTAssertEqual(NRMAPlatform_Native, [devInfo platform]);
    XCTAssertNoThrow([devInfo asDictionary]);
    XCTAssertEqual([devInfo hash], [[NRMADeviceInformation new] hash]);
    XCTAssertNoThrow([[NRMADeviceInformation alloc] initWithDictionary:nil]);
}

- (void) testCorrectness
{
    NSString* osName = @"iOS";
    NSString* osVersion = @"1.0";
    NSString* model = @"iPhone4,3";
    NSString* agentName = @"iOS Agent";
    NSString* agentVersion =@"-1";
    NSString* deviceId = @"100";
    NSString* countryCode = @"1";
    NSString* regionCode = @"0";
    NSString* manufacturer = @"Apple, Inc.";
    NRMAApplicationPlatform platform = NRMAPlatform_React;
    NRMADeviceInformation* devInfo = [NRMADeviceInformation new];

    devInfo.osName = osName;
    devInfo.osVersion = osVersion;
    devInfo.model = model;
    devInfo.agentName = agentName;
    devInfo.agentVersion = agentVersion;
    devInfo.deviceId = deviceId;
    devInfo.countryCode = countryCode;
    devInfo.regionCode = regionCode;
    devInfo.platform = platform;
    devInfo.manufacturer = manufacturer;
    devInfo.misc = [NSMutableDictionary new];
    NSDictionary* dict =  @{@(__kNRMA_RA_platform):
                                [NewRelicInternalUtils stringFromNRMAApplicationPlatform:platform], @(__kNRMA_RA_platformVersion):agentVersion};
    XCTAssertEqual([devInfo asDictionary][kNRMADeviceInfoOSName], osName);
    XCTAssertEqual([devInfo asDictionary][kNRMADeviceInfoOSVersion], osVersion);
    XCTAssertEqual([devInfo asDictionary][kNRMADeviceInfoManufacturer], manufacturer);
    XCTAssertEqual([devInfo asDictionary][kNRMADeviceInfoModel], model);
    XCTAssertEqual([devInfo asDictionary][kNRMADeviceInfoAgentName], agentName);
    XCTAssertEqual([devInfo asDictionary][kNRMADeviceInfoAgentVersion], agentVersion);
    XCTAssertEqual([devInfo asDictionary][kNRMADeviceInfoDeviceId], deviceId);
    XCTAssertEqual([devInfo asDictionary][kNRMADeviceInfoCountryCode], countryCode);
    XCTAssertEqual([devInfo asDictionary][kNRMADeviceInfoRegionCode], regionCode);
    XCTAssertEqualObjects([devInfo asDictionary][kNRMADeviceInfoMisc],dict);
    ;
    //platform version should be the agent version if not explicitly set
    XCTAssertEqualObjects([devInfo JSONObject][9][@(__kNRMA_RA_platformVersion)], agentVersion);

    XCTAssertEqual([devInfo asDictionary][kNRMADeviceInfoRegionCode], regionCode);


    [devInfo setPlatformVersion:@"666"];

    XCTAssertEqualObjects([devInfo JSONObject][0], osName);
    XCTAssertEqualObjects([devInfo JSONObject][1], osVersion);
    XCTAssertEqualObjects([devInfo JSONObject][2], model);
    XCTAssertEqualObjects([devInfo JSONObject][3], agentName);
    XCTAssertEqualObjects([devInfo JSONObject][4], agentVersion);
    XCTAssertEqualObjects([devInfo JSONObject][5], deviceId);
    XCTAssertEqualObjects([devInfo JSONObject][6], countryCode);
    XCTAssertEqualObjects([devInfo JSONObject][7], regionCode);
    XCTAssertEqualObjects([devInfo JSONObject][8], manufacturer);
    XCTAssertEqualObjects([devInfo JSONObject][9][@(__kNRMA_RA_platform)], [NewRelicInternalUtils stringFromNRMAApplicationPlatform:platform]);
    XCTAssertEqualObjects([devInfo JSONObject][9][@(__kNRMA_RA_platformVersion)], @"666");


}



@end
