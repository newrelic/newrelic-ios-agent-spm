//
//  TestHexUploadPublisher.m
//  NewRelic
//
//  Created by Bryce Buchanan on 7/21/17.
//  Copyright (c) 2017 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HexUploadPublisher.hpp"
#import <OCMock/OCMock.h>
#import "NRMAHexUploader.h"
#import <Hex/HexReportContext.hpp>
#import "NRAgentTestBase.h"
struct UploaderImpl {
    NRMAHexUploader* wrapper;
};

namespace NewRelic {
    namespace Hex {

        class TestHexUploadPublisher : public HexUploadPublisher {
        public:
            TestHexUploadPublisher(const char* storePath, const char* appToken, const char* appVersion, const char* collectorAddress)
                    : HexUploadPublisher(storePath, appToken, appVersion, collectorAddress) {}

            UploaderImpl* getUploaderImpl() {
              return this->uploaderImpl();
          }
        };
    }
}

@interface TestHexUploadPublisher : NRMAAgentTestBase
{
    std::shared_ptr<NewRelic::Hex::HexReportContext> context;
    std::shared_ptr<NewRelic::Hex::Report::HandledException> e;
    std::shared_ptr<NewRelic::Hex::Report::AppInfo> applicationInfo;
    std::string sessionId;
    NewRelic::AttributeValidator* attributeValidator;
}
@end


@implementation TestHexUploadPublisher

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    auto appLicense = std::make_shared<NewRelic::Hex::Report::ApplicationLicense>("ABCDEF12345");
    applicationInfo = std::make_shared<NewRelic::Hex::Report::AppInfo>(appLicense.get(),fbs::Platform_iOS);
    attributeValidator = new NewRelic::AttributeValidator([](const char*) {return true;},[](const char*) {return true;},[](const char*) {return true;});
    context = std::make_shared<NewRelic::Hex::HexReportContext>(applicationInfo,*attributeValidator);
    sessionId = std::string("ABSDFWERQWE");
    e = std::make_shared<NewRelic::Hex::Report::HandledException>(sessionId,
                                                                          1,
                                                                          "The tea is too hot.",
                                                                          "HotTeaException",
                                                                          std::vector<std::shared_ptr<NewRelic::Hex::Report::Thread>>());
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    delete attributeValidator;
    [super tearDown];
}

- (void)testHexUploaderCreation {

    auto appLicense = std::make_shared<NewRelic::Hex::Report::ApplicationLicense>("ABCDEF12345");
    std::shared_ptr<NewRelic::Hex::Report::AppInfo> applicationInfo = std::make_shared<NewRelic::Hex::Report::AppInfo>(appLicense.get(),fbs::Platform_iOS);
    NewRelic::AttributeValidator* attributeValidator = new NewRelic::AttributeValidator([](const char*) {return true;},[](const char*) {return true;},[](const char*) {return true;});
    std::shared_ptr<NewRelic::Hex::HexReportContext> context = std::make_shared<NewRelic::Hex::HexReportContext>(applicationInfo,*attributeValidator);
    std::shared_ptr<NewRelic::Hex::Report::HandledException> exception = std::make_shared<NewRelic::Hex::Report::HandledException>("sessionId",
                                                                          1,
                                                                          "The tea is too hot.",
                                                                          "HotTeaException",
                                                                          std::vector<std::shared_ptr<NewRelic::Hex::Report::Thread>>());

    auto uploadPublisher = new NewRelic::Hex::HexUploadPublisher(".","AppToken", "1.0", "staging-mobile-collector.staging.com");
    XCTAssertTrue(uploadPublisher!=NULL);
}


- (void) testHexUploaderWrapper {


    auto appLicense = std::make_shared<NewRelic::Hex::Report::ApplicationLicense>("ABCDEF12345");
    std::shared_ptr<NewRelic::Hex::Report::AppInfo> applicationInfo = std::make_shared<NewRelic::Hex::Report::AppInfo>(appLicense.get(),fbs::Platform_iOS);
    NewRelic::AttributeValidator* attributeValidator = new NewRelic::AttributeValidator([](const char*) {return true;},[](const char*) {return true;},[](const char*) {return true;});
    std::shared_ptr<NewRelic::Hex::HexReportContext> context = std::make_shared<NewRelic::Hex::HexReportContext>(applicationInfo,*attributeValidator);
    std::shared_ptr<NewRelic::Hex::Report::HandledException> exception = std::make_shared<NewRelic::Hex::Report::HandledException>("sessionId",
                                                                                                                                   1,
                                                                                                                                   "The tea is too hot.",
                                                                                                                                   "HotTeaException",
                                                                                                                                   std::vector<std::shared_ptr<NewRelic::Hex::Report::Thread>>());

    auto uploadPublisher = new NewRelic::Hex::TestHexUploadPublisher(".","AppToken", "1.0", "staging-mobile-collector.staging.com");
    auto uploader = uploadPublisher->getUploaderImpl();

    id mockWrapper = [OCMockObject partialMockForObject:((UploaderImpl*)uploader)->wrapper];

    [[mockWrapper expect] sendData:OCMOCK_ANY];

    context->insert(context->createReport(e));

    context->finalize();

    uploadPublisher->publish(context);

    XCTAssertNoThrow([mockWrapper verify]);
}
@end
