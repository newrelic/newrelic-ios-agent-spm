 //
//  NRMAHandledExceptions.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 6/26/17.
//  Copyright © 2017 New Relic. All rights reserved.
//

#import "NRMAHandledExceptions.h"

#include <Hex/HexController.hpp>
#include <Hex/HexPersistenceManager.hpp>
#import "NewRelicInternalUtils.h"
#import "NRMAExceptionReportAdaptor.h"
#import "NRLogger.h"
#import "HexUploadPublisher.hpp"
#import "NRMAHarvestController.h"
#import "NRMAAppToken.h"
#include <Analytics/Constants.hpp>
#include <execinfo.h>

@interface NRMAAnalytics(Protected)
//super hacky, but we can't expose the API on the header of the NRMAAnalytics
//class because it interfaces with not objective-c++ files :(
- (std::shared_ptr<NewRelic::AnalyticsController>&) analyticsController;
@end


const NSString* kHexBackupStoreFolder = @"hexbkup/";

@implementation NRMAHandledExceptions {
    NewRelic::Hex::HexController* _controller;
    std::shared_ptr<NewRelic::AnalyticsController> _analytics;
    std::shared_ptr<NewRelic::Hex::HexPersistenceManager> _persistenceManager;
    std::shared_ptr<NewRelic::Hex::HexStore> _store;
    NewRelic::Hex::Report::ApplicationLicense* _appLicense;
    NewRelic::Hex::HexUploadPublisher* _publisher;
}

- (void) dealloc {

    delete _controller;
    delete _appLicense;
    delete _publisher;


    self.sessionId = nil;
    self.sessionStartDate = nil;
    [super dealloc];
}

- (instancetype) initWithAnalyticsController:(NRMAAnalytics*)analytics
                            sessionStartTime:(NSDate*)sessionStartDate
                          agentConfiguration:(NRMAAgentConfiguration*)agentConfiguration
                                    platform:(NSString*)platform
                                   sessionId:(NSString*)sessionId {
    if (analytics == nil || sessionStartDate == nil || [agentConfiguration applicationToken] == nil || platform == nil || sessionId == nil) {
        NSMutableArray* missingParams = [[NSMutableArray new] autorelease];
        if ([agentConfiguration applicationToken] == nil) [missingParams addObject:@"appToken"];
        if (platform == nil) [missingParams addObject:@"platformName"];
        if (sessionId == nil) [missingParams addObject:@"sessionId"];
        if (analytics == nil) [missingParams addObject:@"AnalyticsController"];
        if (sessionStartDate == nil) [missingParams addObject:@"SessionStartData"];
        NRLOG_ERROR(@"Failed to create handled exception object. Key parameter(s) are nil: %@. This will prevent handle exception reporting.",  [missingParams componentsJoinedByString:@", "]);
        return nil;
    }
    self = [super init];
    if (self) {
        _analytics = std::shared_ptr<NewRelic::AnalyticsController>([analytics analyticsController]);
        self.sessionStartDate = sessionStartDate;
        std::vector<std::shared_ptr<NewRelic::Hex::Report::Library>> libs;
        NSString* appToken = agentConfiguration.applicationToken.value;
        NSString* protocol = agentConfiguration.useSSL?@"https://":@"http://";
        NSString* hexCollectorPath = @"/mobile/f";
        NSString* collectorHost = [NSString stringWithFormat:@"%@%@%@",
                                                             protocol,
                                                             agentConfiguration.collectorHost,
                                                             hexCollectorPath];

        NSString* version = [NRMAAgentConfiguration connectionInformation].applicationInformation.appVersion;


        if (appToken == nil || appToken.length == 0) {
            NRLOG_ERROR(@"Failed to create Handled Exception Manager: missing application token.");
            return nil;
        }

        if (version == nil || version.length == 0) {
            NRLOG_ERROR(@"Failed to create Handled Exception Manager: no version number.");
            return nil;
        }

        if (collectorHost == nil || collectorHost.length == 0) {
            NRLOG_ERROR(@"Failed to create Handled Exception Manager: no host specified.");
            return nil;
        }

        if (sessionId == nil || sessionId.length == 0) {
            NRLOG_ERROR(@"Failed to create Handled Exception Manager: session id not specified.");
            return nil;
        }


        self.sessionId = sessionId;

        _appLicense = new NewRelic::Hex::Report::ApplicationLicense(appToken.UTF8String);


        _publisher = new NewRelic::Hex::HexUploadPublisher([NewRelicInternalUtils getStorePath].UTF8String,
                                                                        appToken.UTF8String,
                                                                        version.UTF8String,
                                                                        collectorHost.UTF8String);


        NSString* backupStorePath = [NSString stringWithFormat:@"%@/%@",[NewRelicInternalUtils getStorePath],kHexBackupStoreFolder];

        [[NSFileManager defaultManager] createDirectoryAtPath:backupStorePath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];

        _store = std::make_shared<NewRelic::Hex::HexStore>(backupStorePath.UTF8String);

        _persistenceManager = std::make_shared<NewRelic::Hex::HexPersistenceManager>(_store,_publisher);

        _controller = new NewRelic::Hex::HexController(std::shared_ptr<const NewRelic::AnalyticsController>(_analytics), std::make_shared<NewRelic::Hex::Report::AppInfo>(_appLicense, [self fbsPlatformFromString:platform]), _publisher, _store, sessionId.UTF8String);
    }
    return self;
}

- (void) onHarvest {
    _controller->publish();
    //todo: improve publish stack to not require this publisher call.
    _store->clear();
    _publisher->retry();

}


- (fbs::Platform) fbsPlatformFromString:(NSString*)platform {
    if ([platform isEqualToString:NRMA_OSNAME_TVOS]) {
        return fbs::Platform_tvOS;
    }
    return fbs::Platform_iOS;
}


- (void) recordError:(NSError *)error
          attributes:(NSDictionary*)attributes
{
    void* callstack[1024];
    int frames = backtrace(callstack,1024);

    auto report = _controller->createReport(uint64_t([[[NSDate new] autorelease] timeIntervalSince1970] * 1000),
                                            error.localizedDescription.UTF8String,
                                            error.domain.UTF8String,
                                            [self createThreadVector:callstack length:frames]
    );

    NRMAExceptionReportAdaptor* contextAdapter = [[[NRMAExceptionReportAdaptor alloc] initWithReport:report] autorelease];

    if (attributes != nil) {
        [contextAdapter addAttributes:attributes];
    }

    report->setAttribute("timeSinceLoad", [[[NSDate new] autorelease] timeIntervalSinceDate:self.sessionStartDate]);

    report->setAttribute("isHandledError", true);

    _controller->submit(report);

}

- (void) recordHandledException:(NSException*)exception
                     attributes:(NSDictionary*)attributes {
    if (exception == nil) {
        NRLOG_ERROR(@"Ignoring nil exception.");
        return;
    }


    NSString* eName = exception.name;
    if(!eName) {
        eName = NSStringFromClass([exception class]);
    }

    if (!exception.callStackReturnAddresses.count) {
        NRLOG_ERROR(@"Invalid exception. \"%@\" was recorded without being thrown. +[NewRelic %@] is reserved for thrown exceptions only.", eName, NSStringFromSelector(_cmd));
        return;
    }


    NSString* eReason = @"";
    if(exception.reason) {
        eReason = exception.reason;
    }

    auto report = _controller->createReport(uint64_t([[[NSDate new] autorelease] timeIntervalSince1970] * 1000),
                                                 eReason.UTF8String,
                                                 eName.UTF8String,
                                                 [self createThreadVector:exception]);



    report->setAttribute("timeSinceLoad", [[[NSDate new] autorelease] timeIntervalSinceDate:self.sessionStartDate]);


    NRMAExceptionReportAdaptor* contextAdapter = [[[NRMAExceptionReportAdaptor alloc] initWithReport:report] autorelease];

    if (attributes != nil) {
        [contextAdapter addAttributes:attributes];
    }


    _controller->submit(report);
}


- (void) recordHandledException:(NSException*)exception {
    [self recordHandledException:exception
                      attributes:nil];
}

- (std::vector<std::shared_ptr<NewRelic::Hex::Report::Thread>>) createThreadVector:(void**)stack length:(int)length {
    std::vector<std::shared_ptr<NewRelic::Hex::Report::Thread>> threadVector;
    std::vector<NewRelic::Hex::Report::Frame> frameVector;

    for(int i = 2; i < length; i++) {
        frameVector.push_back(NewRelic::Hex::Report::Frame(" ", (uint64_t)stack[i]));
    }
    threadVector.push_back(std::make_shared<NewRelic::Hex::Report::Thread>(frameVector));
    return threadVector;
}


- (std::vector<std::shared_ptr<NewRelic::Hex::Report::Thread>>) createThreadVector:(NSException*)exception {
    std::vector<std::shared_ptr<NewRelic::Hex::Report::Thread>> threadVector;
    std::vector<NewRelic::Hex::Report::Frame> frameVector;

    //We want to use callStackReturnAddresses rather than callStackSymbols
    //It is a much less expensive call, and symbols will not be available
    //On symbol-stripped binaries, anyway.
    for (NSNumber* frame in exception.callStackReturnAddresses) {
        frameVector.push_back(NewRelic::Hex::Report::Frame(" ", [frame unsignedLongLongValue]));
    }
    threadVector.push_back(std::make_shared<NewRelic::Hex::Report::Thread>(frameVector));
    return threadVector;
}

- (void) processAndPublishPersistedReports {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        auto context = _persistenceManager->retrieveStoreReports();
        if (context) {
            _publisher->publish(context);
        }
    });
}

@end

