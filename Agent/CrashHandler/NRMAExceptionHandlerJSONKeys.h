
#import <mach/machine.h> 
#import <Foundation/Foundation.h>


//PLcrashReport keys
extern NSString const * kNRMAReportSysInfo;
extern NSString const * kNRMAReportHasMachInfo;
extern NSString const * kNRMAReportMachInfo;
extern NSString const * kNRMAReportAppInfo;
extern NSString const * kNRMAReportHasProcInfo;
extern NSString const * kNRMAReportProcInfo;
extern NSString const * kNRMAReportSignalInfo;
extern NSString const * kNRMAReportMachExcepInfo;
extern NSString const * kNRMAReportThreads;
extern NSString const * kNRMAReportImages;
extern NSString const * kNRMAReportExceptionInfo;
extern NSString const * kNRMAUUID;

//PLCrashReporterSystemOS keys
extern NSString const * kNRMASYSOS_iOS; 
extern NSString const * kNRMASYSOS_OSX; 
extern NSString const * kNRMASYSOS_Sim; 
extern NSString const * kNRMASYSOS_Unkwn; 

//PLCrashReportSystemInfo keys
extern NSString const * kNRMADeviceName; 
extern NSString const * kNRMAOSVersion; 
extern NSString const * kNRMAOSBuild; 

//PLCrashReprotMachineInfo keys
extern NSString const * kNRMAModelName; 
extern NSString const * kNRMAProcInfo; 

//PLCrashReportProcessorInfo keys
extern NSString const * kNRMAProcTypeEncode; 
extern NSString const * kNRMAArchitecture; 

//PLCrashReportProcessInfo keys
extern NSString const * kNRMAProcessName; 
extern NSString const * kNRMAProcessID; 
extern NSString const * kNRMAProcessPath; 
extern NSString const * kNRMAParentProcessName; 
extern NSString const * kNRMAParentProcessID; 

//PLCrashReportApplicationInfo keys
extern NSString const * kNRMAAppId; 
extern NSString const * kNRMAAppVersion; 

//PLCRashReportSignalInfo keys
extern NSString const * kNRMASignalName; 
extern NSString const * kNRMASignalCode; 
extern NSString const * kNRMASignalAddr; 

//PLCrashReportMachExceptionInfo keys
extern NSString const * kNRMAMachExcepType; 
extern NSString const * kNRMAMachExcepCodes; 

//PLCrashReportExceptionInfo keys
extern NSString const *  kNRMAExceptionInfoName; 
extern NSString const *  kNRMAExceptionInfoReason; 

//PLCrashReportThreadInfo keys
extern NSString const *  kNRMAThreadInfoNumber; 
extern NSString const *  kNRMAThreadInfoStackFrame;  
extern NSString const *  kNRMAThreadInfoRegisters; 
extern NSString const *  kNRMAThreadInfoCrashed; 

//PLCrashReportStackFrameInfo keys
extern NSString const *  kNRMAStackFrameInstructio;
extern NSString const *  kNRMAStackFrameSymbolInfo; 

//PLCrashReportSymbolInfo keys
extern NSString const *  kNRMASymbolInfoSymbolName; 
extern NSString const *  kNRMASymbolInfoStartAddr; 

//PLCrashReportBinaryImageInfo keys
extern NSString const *  kNRMABinaryImageCodeType; 
extern NSString const *  kNRMABinaryImageBaseAddr;
extern NSString const *  kNRMABinaryImageSize; 
