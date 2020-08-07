//
//  NRMAExceptionHandlerasdfasdf.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 6/20/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAExceptionHandlerJSONKeys.h"


#import "mach/machine.h"


//PLcrashReport keys
NSString const * kNRMAReportSysInfo        =  @"System Info";
NSString const * kNRMAReportHasMachInfo    =  @"HasMachInfo";
NSString const * kNRMAReportMachInfo       =  @"Mach Info";
NSString const * kNRMAReportAppInfo        =  @"Application Info";
NSString const * kNRMAReportHasProcInfo    =  @"HasProcInfo";
NSString const * kNRMAReportProcInfo       =  @"Process Info";
NSString const * kNRMAReportSignalInfo     =  @"Signal Info";
NSString const * kNRMAReportMachExcepInfo  =  @"Mach Exception Info";
NSString const * kNRMAReportThreads        =  @"Threads";
NSString const * kNRMAReportImages         =  @"Images";
NSString const * kNRMAReportExceptionInfo  =  @"Exception Info";
NSString const * kNRMAUUID                 =  @"uuidRef";

//PLCrashReporterSystemOS keys;
NSString const * kNRMASYSOS_iOS             = @"iOS Device";
NSString const * kNRMASYSOS_OSX             = @"OSX";
NSString const * kNRMASYSOS_Sim             = @"iOS Simulator";
NSString const * kNRMASYSOS_Unkwn           = @"Unknown";

//PLCrashReportSystemInfo keys;
NSString const * kNRMADeviceName            = @"Device Name";
NSString const * kNRMAOSVersion             = @"OS Version";
NSString const * kNRMAOSBuild               = @"OS Build";

//PLCrashReprotMachineInfo keys;
NSString const * kNRMAModelName             = @"Model Name";
NSString const * kNRMAProcInfo              = @"Processor Info";

//PLCrashReportProcessorInfo keys;
NSString const * kNRMAProcTypeEncode        = @"Type Encoding";
NSString const * kNRMAArchitecture          = @"ARCH";

//PLCrashReportProcessInfo keys;
NSString const * kNRMAProcessName           =  @"Process";
NSString const * kNRMAProcessID             =  @"Process ID";
NSString const * kNRMAProcessPath           =  @"Process Path";
NSString const * kNRMAParentProcessName     =  @"Parent Process";
NSString const * kNRMAParentProcessID       =  @"Parent Process ID";

//PLCrashReportApplicationInfo keys;
NSString const * kNRMAAppId                 =  @"Application Identifier";
NSString const * kNRMAAppVersion            =  @"Application Version";

//PLCRashReportSignalInfo keys;
NSString const * kNRMASignalName            =  @"Signal Name";
NSString const * kNRMASignalCode            =  @"Signal Code";
NSString const * kNRMASignalAddr            =  @"Fault Address";

//PLCrashReportMachExceptionInfo keys;
NSString const * kNRMAMachExcepType         =  @"Mach Exception Type";
NSString const * kNRMAMachExcepCodes        =  @"Mach Exception Codes";

//PLCrashReportExceptionInfo keys;
NSString const *  kNRMAExceptionInfoName     =   @"Exception Name";
NSString const *  kNRMAExceptionInfoReason   =   @"Exception cause";

//PLCrashReportThreadInfo keys;
NSString const *  kNRMAThreadInfoNumber      =  @"Thread Number";
NSString const *  kNRMAThreadInfoStackFrame  =  @"Stack Frames";
NSString const *  kNRMAThreadInfoRegisters   =  @"Registers";
NSString const *  kNRMAThreadInfoCrashed     =  @"Crashed";

//PLCrashReportStackFrameInfo keys;
NSString const *  kNRMAStackFrameInstruction =  @"Instrunction Pointer";
NSString const *  kNRMAStackFrameSymbolInfo  =  @"Symbol Info";

//PLCrashReportSymbolInfo keys;
NSString const *  kNRMASymbolInfoSymbolName =  @"Symbol Name";
NSString const *  kNRMASymbolInfoStartAddr  =  @"Start Address";

//PLCrashReportBinaryImageInfo keys;
NSString const *  kNRMABinaryImageCodeType  =  @"Code Type";
NSString const *  kNRMABinaryImageBaseAddr  =  @"Base Address";
NSString const *  kNRMABinaryImageSize      =  @"Image Size";
