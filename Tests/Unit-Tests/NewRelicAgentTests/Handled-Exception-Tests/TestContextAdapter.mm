//
//  TestContextAdapter.m
//  NewRelic
//
//  Created by Bryce Buchanan on 7/7/17.
//  Copyright (c) 2017 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Hex/HexPublisher.hpp>
#import <Hex/HexController.hpp>
#import <Hex/HexContext.hpp>
#import <OCMock/OCMock.h>
#import "NewRelicInternalUtils.h"
#import "NRMAExceptionReportAdaptor.h"
#import "NRMAAnalytics.h"
#import "NRMABool.h"

@interface NRMAAnalytics ()
- (std::shared_ptr<NewRelic::AnalyticsController>&) analyticsController;
@end

@interface NRMAExceptionReportAdaptor ()
- (void) addKey:(NSString*)key
    stringValue:(NSString*)string;

- (void) addKey:(NSString*)key
      boolValue:(NRMABool*)boolean;

- (void) addKey:(NSString*)key
    numberValue:(NSNumber*)num;
@end

@interface TestContextAdapter : XCTestCase
{
    NewRelic::Hex::Report::ApplicationLicense* _appLicense;
    NewRelic::Hex::HexController* _controller;
    NRMAAnalytics* _analytics;
    NewRelic::Hex::HexPublisher* _publisher;
}
@end

@implementation TestContextAdapter

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _analytics = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:0];
    [_analytics removeAllSessionAttributes];
    _appLicense = new NewRelic::Hex::Report::ApplicationLicense("appToken");
    auto appInfo = std::make_shared<NewRelic::Hex::Report::AppInfo>(_appLicense,fbs::Platform_iOS);
    _publisher = new NewRelic::Hex::HexPublisher([NewRelicInternalUtils getStorePath].UTF8String);
    auto store = std::make_shared<NewRelic::Hex::HexStore>([NewRelicInternalUtils getStorePath].UTF8String);
    _controller = new NewRelic::Hex::HexController([_analytics analyticsController],appInfo,_publisher, store,"sessionId");
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    _analytics = nil;
    delete _appLicense;
    delete _controller;
    delete _publisher;
    [_analytics removeAllSessionAttributes];
    [super tearDown];
}


- (void) testHandleSessionAttribute {

    XCTAssertTrue([_analytics setSessionAttribute:@"bool"
                              value:[[NRMABool alloc] initWithBOOL:NO]]);

    XCTAssertTrue([_analytics setSessionAttribute:@"Banana"
                              value:@"Tally me."]);

    XCTAssertTrue([_analytics setSessionAttribute:@"anotherLong"
                              value:@10000]);

    XCTAssertTrue([_analytics setSessionAttribute:@"anotherDouble"
                              value:@10.555]);


    auto report = _controller->createReport(0, "msg", "name", std::vector<std::shared_ptr<NewRelic::Hex::Report::Thread>>());

    auto lngMap = report->getLongAttributes()->get_attributes();
    auto boolMap = report->getBooleanAttributes()->get_attributes();
    auto strMap = report->getStringAttributes()->get_attributes();
    auto dblMap = report->getDoubleAttributes()->get_attributes();

    XCTAssertTrue(lngMap.size() == 1);
    XCTAssertTrue(boolMap.size() == 1);
    XCTAssertTrue(strMap.size() == 1);
    XCTAssertTrue(dblMap.size() == 1);


    XCTAssertTrue(lngMap[std::string("anotherLong")] == 10000);
    XCTAssertTrue(dblMap[std::string("anotherDouble")] == 10.555);
    XCTAssertTrue(boolMap[std::string("bool")] == false);
    XCTAssertTrue(strMap[std::string("Banana")] == std::string("Tally me."));

    NRMAExceptionReportAdaptor* adaptor = [[NRMAExceptionReportAdaptor alloc] initWithReport:report];

    [adaptor addAttributes:@{
            @"bool":[[NRMABool alloc] initWithBOOL:YES],
            @"anotherLong":@123,
            @"anotherDouble":@1.1,
            @"Banana":@"Mr Tallyman."
    }];

    lngMap = report->getLongAttributes()->get_attributes();
    boolMap = report->getBooleanAttributes()->get_attributes();
    strMap = report->getStringAttributes()->get_attributes();
    dblMap = report->getDoubleAttributes()->get_attributes();

    XCTAssertTrue(lngMap.size() == 1);
    XCTAssertTrue(boolMap.size() == 1);
    XCTAssertTrue(strMap.size() == 1);
    XCTAssertTrue(dblMap.size() == 1);


    XCTAssertTrue(lngMap[std::string("anotherLong")] == 123);
    XCTAssertTrue(dblMap[std::string("anotherDouble")] == 1.1);
    XCTAssertTrue(boolMap[std::string("bool")] == true);
    XCTAssertTrue(strMap[std::string("Banana")] == std::string("Mr Tallyman."));
}


- (void) testHandleAttributes {

    auto report = _controller->createReport(0, "msg", "name", std::vector<std::shared_ptr<NewRelic::Hex::Report::Thread>>());

    NRMAExceptionReportAdaptor* adaptor = [[NRMAExceptionReportAdaptor alloc] initWithReport:report];

    id mockContextAdaptor = [OCMockObject partialMockForObject:adaptor];

    NRMABool* b = [[NRMABool alloc] initWithBOOL:YES];
    NSString* str = @"string";
    NSNumber* dbl = @2.01;
    NSNumber* lng = @1000LL;

    [[[mockContextAdaptor expect] andForwardToRealObject] addKey:@"bool"
                                                       boolValue:b];

    [[[mockContextAdaptor expect] andForwardToRealObject] addKey:@"str"
                                                     stringValue:str];

    [[[mockContextAdaptor expect]  andForwardToRealObject] addKey:@"dbl"
                                                      numberValue:dbl];

    [[[mockContextAdaptor expect] andForwardToRealObject] addKey:@"lng"
                                                     numberValue:lng];

    NSDictionary* dict = @{
            @"bool":b,
            @"str":str,
            @"dbl":dbl,
            @"lng":lng
    };

    [adaptor addAttributes:dict];

    auto lngMap = report->getLongAttributes()->get_attributes();
    auto boolMap = report->getBooleanAttributes()->get_attributes();
    auto strMap = report->getStringAttributes()->get_attributes();
    auto dblMap = report->getDoubleAttributes()->get_attributes();

    XCTAssertTrue(lngMap.size() == 1, "size was %lu",lngMap.size());
    XCTAssertTrue(boolMap.size() == 1, "size was %lu",boolMap.size());
    XCTAssertTrue(strMap.size() == 1, "size was %lu",strMap.size());
    XCTAssertTrue(dblMap.size() == 1, "size was %lu",dblMap.size());


    XCTAssertTrue(lngMap[std::string("lng")] == lng.longLongValue);
    XCTAssertTrue(dblMap[std::string("dbl")] == dbl.doubleValue);
    XCTAssertTrue(boolMap[std::string("bool")] == b.value);
    XCTAssertTrue(strMap[std::string("str")] == std::string(str.UTF8String));


    [mockContextAdaptor verify];
    [mockContextAdaptor stopMocking];
}

@end
