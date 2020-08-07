//
//  NRMAExceptionReportParser.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/21/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAExceptionReportParser.h"
#import "NRMAExceptionHandlerJSONKeys.h"
//#import "PLCrashReportApplicationInfo+JSON.h"
//#import "PLCrashReportBinaryImageInfo+JSON.h"
//#import "PLCrashReportExceptionInfo+JSON.h"
//#import "PLCrashReportMachExceptionInfo+JSON.h"
//#import "PLCrashReportMachineInfo+JSON.h"
//#import "PLCrashReportProcessInfo+JSON.h"
//#import "PLCrashReportProcessorInfo+JSON.h"
//#import "PLCrashReportRegisterInfo+JSON.h"
//#import "PLCrashReportSignalInfo+JSON.h"
//#import "PLCrashReportStackFrameInfo+JSON.h"
//#import "PLCrashReportSymbolInfo+JSON.h"
//#import "PLCrashReportSystemInfo+JSON.h"
//#import "PLCrashReportThreadInfo+JSON.h"

@implementation NRMAExceptionReportParser

+ (id) JSONObjectFromPLCrashReport:(PLCrashReport*)report
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];

    [dict setObject:[report.systemInfo JSONObject]?:[NSNull null]           forKey:kNRMAReportSysInfo];
    [dict setObject:[report.machineInfo JSONObject]?:[NSNull null]          forKey:kNRMAReportMachInfo];
    [dict setObject:[report.applicationInfo JSONObject]?:[NSNull null]      forKey:kNRMAReportAppInfo];
    [dict setObject:[report.processInfo JSONObject]?:[NSNull null]          forKey:kNRMAReportProcInfo];
    [dict setObject:[report.signalInfo JSONObject]?:[NSNull null]           forKey:kNRMAReportSignalInfo];
    [dict setObject:[report.machExceptionInfo JSONObject]?:[NSNull null]    forKey:kNRMAReportMachExcepInfo];
    [dict setObject:[report.exceptionInfo JSONObject]?:[NSNull null]        forKey:kNRMAReportExceptionInfo];

    NSMutableArray* threads = [[NSMutableArray alloc] initWithCapacity:report.threads.count];
    for (PLCrashReportThreadInfo* threadInfo in report.threads) {
        id threadJSON = [threadInfo JSONObject];
        if (threadJSON != nil) {
            [threads addObject:threadJSON];
        }
    }

    [dict setObject:threads forKey:kNRMAReportThreads];

    NSMutableArray* images = [[NSMutableArray alloc] initWithCapacity:report.images.count];
    for (PLCrashReportBinaryImageInfo* binImage in report.images) {
        id imageJSON = [binImage JSONObject];
        if (imageJSON != nil) {
            [images addObject:imageJSON];
        }
    }

    [dict setObject:images forKey:kNRMAReportImages];

    NSString* UUID = (NSString*)CFBridgingRelease(CFUUIDCreateString(NULL, report.uuidRef));
    [dict setObject:UUID forKey:kNRMAUUID];
    return dict;
}

@end

