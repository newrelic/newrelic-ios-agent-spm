//
//  NRMAExceptionDataWrapper.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/28/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#ifndef NewRelicAgent_NRMAExceptionMetaDataStore_h
#define NewRelicAgent_NRMAExceptionMetaDataStore_h

#include <sys/signal.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define kNRMAMetaKey_AppName             "appname"
#define kNRMAMetaKey_AppData             "appdata"
#define kNRMAMetaKey_AppToken            "apptoken"
#define kNRMAMetaKey_AppVersion          "appversion"
#define kNRMAMetaKey_BuildId             "buildidentifier"
#define kNRMAMetaKey_DiskFree            "diskfree"
#define kNRMAMetaKey_ModelNumber         "modelnumber"
#define kNRMAMetaKey_MemoryUse           "memoryusage"
#define kNRMAMetaKey_Orientation         "orientation"
#define kNRMAMetaKey_NetworkConnectivity "networkconnectivity"
#define kNRMAMetaKey_SessionStartTime    "sessionstarttime"
#define kNRMAMetaKey_AgentId             "agentid"
#define kNRMAMetaKey_AccountId           "accountid"
#define kNRMAMetaKey_Transactions        "transactions"
#define kNRMAMetaKey_Session             "sessionid"
#define kNRMAMetaKey_Build               "build"
#define kNRMAMetaKey_CrashTime           "crashtime"

#define kNRMAMetaFileName    "metadata.nr.crash"


    void NRMA_updateDiskUsage(void);

    void NRMA_setAccountId(uint64_t);
    uint64_t NRMA_getAccountId(void);

    void NRMA_setAgentId(uint64_t);
    uint64_t NRMA_getAgentId(void);

    //session id
    void NRMA_setSessionId(const char*);
    
    const char* NRMA_getSessionId(void);

    //temp dir
    void NRMA_setTempDir(const  char*);

    const char* NRMA_getTempDir(void);

    //AppToken
    void NRMA_setAppToken(const char* appToken);
    
    const char* NRMA_getAppToken(void);
    
    //AppVersion
    void NRMA_setAppVersion(const char* appVersion);
    
    const char* NRMA_getAppVersion(void);
    
    //AppName
    void NRMA_setAppName(const char* appName);
    
    const char* NRMA_getAppName(void);
    
    //BuildIdentifier
    void NRMA_setBuildIdentifier(const char* buildIdentifier);
    
    const char* NRMA_getBuildIdentifier(void);
    
    //orientation
    void NRMA_setOrientation(const char* orientation);
    
    const char* NRMA_getOrientation(void);
    
    //memoryUsage
    void NRMA_setMemoryUsage(const char* memoryUsage);
    
    const char* NRMA_getMemoryUsage(void);
    
    //memorySize
    void NRMA_setMemorySize(const char* memorySize);
    
    const char* NRMA_getMemorySize(void);

    //modelNumber
    void NRMA_updateModelNumber(void);
    const char* NRMA_getModelNumber(void);

    //DiskUsage
    void NRMA_setDiskSize(const char*);
    
    const char* NRMA_getDiskSize(void);
    
    void NRMA_setDiskFree(uint64_t);
    
    uint64_t NRMA_getDiskFree(void);
    
    //NetworkConnectivity
    
    void NRMA_setNetworkConnectivity(const char* networkConnectivity);
    
    const char* NRMA_getNetworkConnectivity(void);
    
    //SessionStartTime
    void NRMA_setSessionStartTime(const char* sessionStartTime);
    
    const char* NRMA_getSessionStartTime(void);

    //BuildNumber
    void NRMA_setBuild(const char* buildNumber);

    const char* NRMA_getBuild(void);

    void NRMA_writeNRMeta(siginfo_t *info, ucontext_t *uap, void *context);
    
    const char* NRMA_createTempFileName(void);



#endif

#ifdef __cplusplus
}
#endif // extern "C" {
