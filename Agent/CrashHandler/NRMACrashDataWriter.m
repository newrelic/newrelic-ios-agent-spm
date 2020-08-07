//
//  NRMACrashDataWriter.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/7/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMACrashDataWriter.h"
#import "NRMACrashReport.h"
#import "NRMAExceptionMetaDataStore.h"
#import "NewRelicInternalUtils.h"
#import "NRMAJSON.h"
#import "NRLogger.h"
#import "NRConstants.h"
#import "NRMAExceptionhandlerConstants.h"
#import <Analytics/Constants.hpp>
#import "NRMATimestampContainer.h"

#define kNRMASYSOS_iOS              @"iOS Device"
#define kNRMASYSOS_OSX              @"OSX"
#define kNRMASYSOS_Sim              @"iOS Simulator"
#define kNRMASYSOS_Unkwn            @"Unknown"
#define kNRMASYSOS_tvOS             @"tvOS Device"
#define kNRMASYSOS_tvSim            @"tvOS Simulator"

@implementation NRMACrashDataWriter

+ (BOOL) writeCrashReport:(PLCrashReport*)report
             withMetaData:(NSDictionary*)metaDictionary
        sessionAttributes:(NSDictionary*)attributes
          analyticsEvents:(NSArray*)events
{

    NSNumber* diskUsage = [metaDictionary objectForKey:@kNRMAMetaKey_DiskFree];
    NSMutableArray* diskUsageArray = [[NSMutableArray alloc] init];
    if (diskUsage) {
        [diskUsageArray addObject:diskUsage];
    }
    NRMACrashReport_DeviceInfo* deviceInfo = [[NRMACrashReport_DeviceInfo alloc] initWithMemoryUsage:[metaDictionary objectForKey:@kNRMAMetaKey_MemoryUse]
                                                                                         orientation:[metaDictionary objectForKey:@kNRMAMetaKey_Orientation]
                                                                                       networkStatus:[metaDictionary objectForKey:@kNRMAMetaKey_NetworkConnectivity]
                                                                                           diskUsage:diskUsageArray
                                                                                           osVersion:report.systemInfo.operatingSystemVersion
                                                                                          deviceName:[self getOperatingDevice:report.systemInfo.operatingSystem]
                                                                                             osBuild:report.systemInfo.operatingSystemBuild
                                                                                        architecture:[self getArchitectureFromProcessorInfo:report.machineInfo.processorInfo]
                                                                                         modelNumber:[metaDictionary objectForKey:@kNRMAMetaKey_ModelNumber]
                                                                                          deviceUuid:[NewRelicInternalUtils deviceId]];

    NRMACrashReport_AppInfo* appInfo = [[NRMACrashReport_AppInfo alloc] initWithAppName:[metaDictionary objectForKey:@kNRMAMetaKey_AppName]
                                                                             appVersion:[metaDictionary objectForKey:@kNRMAMetaKey_AppVersion]
                                                                               appBuild:[metaDictionary objectForKey:@kNRMAMetaKey_Build]
                                                                               bundleId:[[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString*)kCFBundleIdentifierKey]
                                                                            processPath:report.processInfo.processPath
                                                                            processName:report.processInfo.processName
                                                                              processId:[NSNumber numberWithUnsignedInteger:report.processInfo.processID]
                                                                          parentProcess:report.processInfo.parentProcessName
                                                                        parentProcessId:[NSNumber numberWithUnsignedInteger:report.processInfo.parentProcessID]];

    NRMACrashReport_SignalInfo* signalInfo = [[NRMACrashReport_SignalInfo alloc] initWithFaultAddress:[NSString stringWithFormat:@"%#llx",report.signalInfo.address]
                                                                                           signalCode:report.signalInfo.code
                                                                                           signalName:report.signalInfo.name];

    NRMACrashReport_Exception* exception = [[NRMACrashReport_Exception alloc] initWithName:report.exceptionInfo.exceptionName
                                                                                     cause:report.exceptionInfo.exceptionReason
                                                                                signalInfo:signalInfo];




    NSMutableArray* exceptionStackFrames = nil;
    if (report.exceptionInfo != nil) {
        /* 
         * report.exceptionInfo is a special crash case 
         *
         * this is a Runtime-exception and the crash frame is stored within 
         * the report.exceptionInfo.stackFrames. The crash thread that is living
         * in report.threads is a thread that is all hacked up from the exception
         * handling. We will replaced the crash thread from report.threads with 
         * the one gathered from here.
         *
         */
        exceptionStackFrames = [[NSMutableArray alloc] init];
        for (PLCrashReportStackFrameInfo* stackFrameInfo in report.exceptionInfo.stackFrames) {
            NRMACrashReport_Symbol* symbol = [[NRMACrashReport_Symbol alloc] initWithSymbolStartAddr:[NSString stringWithFormat:@"%#llx",stackFrameInfo.symbolInfo.startAddress]
                                                                                          symbolName:stackFrameInfo.symbolInfo.symbolName];

            [exceptionStackFrames addObject:[[NRMACrashReport_Stack alloc] initWithInstructionPointer:[NSString stringWithFormat:@"%#llx",stackFrameInfo.instructionPointer]
                                                                                      symbol:symbol]?:[NSNull null]];
        }
    }


    // process threads
    NSMutableArray* threads = [[NSMutableArray alloc] init];

    for (PLCrashReportThreadInfo* threadInfo in report.threads) {
        NSMutableDictionary* registers = [[NSMutableDictionary alloc] init];
        if (threadInfo.crashed) {
            for (PLCrashReportRegisterInfo* regInfo in threadInfo.registers ) {
                NSString* registerValue = [NSString stringWithFormat:@"%#llx",regInfo.registerValue];
                [registers setObject:registerValue?:[NSNull null] forKey:regInfo.registerName];
            }
        }

        NSMutableArray* stackFrames = [[NSMutableArray alloc] init];
        for (PLCrashReportStackFrameInfo* stackFrameInfo in threadInfo.stackFrames) {
           NRMACrashReport_Symbol* symbol = [[NRMACrashReport_Symbol alloc] initWithSymbolStartAddr:[NSString stringWithFormat:@"%#llx",stackFrameInfo.symbolInfo.startAddress]
                                                                                         symbolName:stackFrameInfo.symbolInfo.symbolName];

            [stackFrames addObject:[[NRMACrashReport_Stack alloc] initWithInstructionPointer:[NSString stringWithFormat:@"%#llx",stackFrameInfo.instructionPointer]
                                                                                      symbol:symbol]?:[NSNull null]];
        }

        //
        if (threadInfo.crashed && exceptionStackFrames != nil) {
            /* 
             * We've found a runtime exception thread which we will replace
             * the report.threads crash thread with exceptionStackFrames.
             */
            stackFrames = exceptionStackFrames;
        }
        [threads addObject:[[NRMACrashReport_Thread alloc] initWithCrashed:threadInfo.crashed
                                                                registers:registers
                                                             threadNumber:[NSNumber numberWithInteger:threadInfo.threadNumber]
                                                                 threadId:nil
                                                                 priority:nil
                                                                    stack:stackFrames]];
    }




    //process libraries
    NSMutableArray* libraries = [[NSMutableArray alloc] init];

    NSString* currentImagePath = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] bundlePath], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"]];
    NSString* buildIdentifier = @"";

    for (PLCrashReportBinaryImageInfo* binImgInfo in report.images) {
        NRMACrashReport_CodeType* codeType = [[NRMACrashReport_CodeType alloc] initWithArch:[self getArchitectureFromProcessorInfo:binImgInfo.codeType] typeEncoding:[self getProcessorArchType:binImgInfo.codeType.typeEncoding]];
        [libraries addObject:[[NRMACrashReport_Library alloc] initWithBaseAddress:[NSString stringWithFormat:@"%#llx",binImgInfo.imageBaseAddress]
                                                                       imageName:binImgInfo.imageName
                                                                       imageSize:[NSNumber numberWithLongLong:binImgInfo.imageSize]
                                                                       imageUuid:binImgInfo.imageUUID
                                                                         codeType:codeType]?:[NSNull null]];
        if ([binImgInfo.imageName isEqualToString:currentImagePath] ) {
            buildIdentifier = binImgInfo.imageUUID;
        }
    }

    NSMutableDictionary* mutableAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];

    //if attribute sessionId doesn't match crash's session id, don't send analytics data.
    if (![[metaDictionary objectForKey:@kNRMAMetaKey_Session] isEqualToString:[mutableAttributes objectForKey:@"sessionId"]]) {
        attributes = nil;
        mutableAttributes = nil;
        events = nil;
    }

    //CrashTime is generated at crash time using time.h time(). This will return -1 if it fails.
    NRMATimestampContainer* crashTime = [[NRMATimestampContainer alloc] initWithTimestamp:((NSNumber*)[metaDictionary objectForKey:@kNRMAMetaKey_CrashTime]).doubleValue];
    if ([crashTime toSeconds] <= 0) {
        //let's use the current time if something goes wrong
        NRLOG_WARNING(@"failed to retreive crash time. relying on \"current time\"");
        crashTime = [[NRMATimestampContainer alloc] initWithTimestamp:NRMAMillisecondTimestamp()];
    }
    double rawSessionStartTime = ((NSString*)metaDictionary[[NSString stringWithUTF8String:kNRMAMetaKey_SessionStartTime]]).doubleValue;
    NRMATimestampContainer* sessionStartTime = [[NRMATimestampContainer alloc] initWithTimestamp:rawSessionStartTime];

    if (mutableAttributes[[NSString stringWithUTF8String:__kNRMA_RA_sessionDuration]] == nil && [sessionStartTime toSeconds] >= 0) {
        mutableAttributes[[NSString stringWithUTF8String:__kNRMA_RA_sessionDuration]] = @([crashTime toSeconds] - [sessionStartTime toSeconds]);
    }
    NRMACrashReport* nrmaReport = [[NRMACrashReport alloc] initWithUUID:(NSString*)CFBridgingRelease(CFUUIDCreateString(NULL, report.uuidRef))
                                                        buildIdentifier:buildIdentifier
                                                              timestamp:@([crashTime toSeconds])
                                                               appToken:[metaDictionary objectForKey:@kNRMAMetaKey_AppToken]
                                                              accountId:[metaDictionary objectForKey:@kNRMAMetaKey_AccountId]
                                                                agentId:[metaDictionary objectForKey:@kNRMAMetaKey_AgentId]
                                                             deviceInfo:deviceInfo
                                                                appInfo:appInfo
                                                              exception:exception
                                                                threads:threads
                                                              libraries:libraries
                                                        activityHistory:[metaDictionary objectForKey:@kNRMAMetaKey_Transactions]
                                                      sessionAttributes:mutableAttributes
                                                        AnalyticsEvents:events];



    //Write to temp file for upload.
    NSString* crashOutputFilePath = [NSString stringWithFormat:@"%@%@/%f.%@",NSTemporaryDirectory(),kNRMA_CR_ReportPath,NRMAMillisecondTimestamp(),kNRMA_CR_ReportExtension];
    NSError* error = nil;

    NSData* crashData = [NRMAJSON dataWithJSONABLEObject:nrmaReport options:0 error:&error];

    if (error) {
        NRLOG_VERBOSE(@"Failed to JSONify crash report data: %@.",error.description);
        return NO;
    }

    [[NSFileManager defaultManager] createDirectoryAtPath:[NSString stringWithFormat:@"%@/%@",NSTemporaryDirectory(),kNRMA_CR_ReportPath]
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];

    if (error) {
        NRLOG_VERBOSE(@"Failed to create crash report directory:  %@",error.description);
    }


     BOOL isWriteSuccessful = [[NSFileManager defaultManager] createFileAtPath:crashOutputFilePath
                                            contents:crashData
                                          attributes:nil];

    if (!isWriteSuccessful) {
        NRLOG_VERBOSE(@"failed to write crash report data to file.");
    }

    return isWriteSuccessful;
}

+ (NSString*) getOperatingDevice:(PLCrashReportOperatingSystem)osEnum
{
    switch (osEnum) {
        case PLCrashReportOperatingSystemMacOSX:
            return kNRMASYSOS_OSX;
            break;
        case PLCrashReportOperatingSystemiPhoneOS:
            return kNRMASYSOS_iOS;
            break;
        case PLCrashReportOperatingSystemiPhoneSimulator:
            return kNRMASYSOS_Sim;
            break;
        case PLCrashReportOperatingSystemtvOS:
            return kNRMASYSOS_tvOS;
            break;
        case PLCrashReportOperatingSystemtvSimulator:
            return kNRMASYSOS_tvSim;
        default:
            return kNRMASYSOS_Unkwn;
            break;
    }
}


+ (NSString*) getArchitectureFromProcessorInfo:(PLCrashReportProcessorInfo*)info
{
    NSString* architecture = nil;
    if (info.typeEncoding == PLCrashReportProcessorTypeEncodingMach) {
        switch (info.type) {
            case CPU_TYPE_ARM:
                architecture = [self subtypesForARM:info.subtype];
                break;
            case CPU_TYPE_ARM64:
                architecture = [self subtypesForARM64:info.subtype];
                break;
            case CPU_TYPE_X86:
                architecture = @"i386";
                break;
            case CPU_TYPE_X86_64:
                architecture = @"x86_64";
                break;
            default:
                break;
        }
    }
    return architecture;
}

+ (NSString*) getProcessorArchType:(PLCrashReportProcessorTypeEncoding)architecture
{
    switch (architecture) {
        case PLCrashReportProcessorTypeEncodingMach:
            return @"Mach";
            break;
        default:
            return @"Unknown";
            break;
    }
}

+ (NSString*) subtypesForARM:(uint64_t)subtype
{
    switch (subtype) {
        case CPU_SUBTYPE_ARM_V7S:
            return @"armv7s";
            break;
        case CPU_SUBTYPE_ARM_V6:
            return @"armv6";
            break;
        case CPU_SUBTYPE_ARM_V7F:
        case CPU_SUBTYPE_ARM_V7:
            return @"armv7";
        default:
            return @"arm-unknown";
            break;
    }
}

+ (NSString*) subtypesForARM64:(uint64_t)subtype
{
    switch (subtype) {
        case CPU_SUBTYPE_ARM64_ALL:
            return @"arm64";
            break;
        case CPU_SUBTYPE_ARM64_V8:
            return @"arm64";
        case CPU_SUBTYPE_ARM64E:
            return @"arm64e";
        default:
            return @"arm64-unknown";
            break;
    }
}


@end
