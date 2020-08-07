//
//  NRMAExceptionDataWrapper.c
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/28/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//


#import "NRMAExceptionMetaDataStore.h"
#include <fcntl.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <mach/mach.h>
#include <errno.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/param.h>
#include <sys/mount.h>
#include <sys/utsname.h>
#import <time.h>


#define MILLI_PER_SECOND 1000
#define NANO_PER_MILLI 1000000


#ifdef __cplusplus
extern "C" {
#endif

#import "NewRelicInternalUtils.h"
#include "NRMAInteractionHistory.h"

    void NRMA_writeInteractionHistory(int fd);
    void NRMA_writeCrashTime(int fd);
    void __NRMA_assign_retain(char** dest, const char* src);
    
    ssize_t NRMA_write(int fd, void* data, size_t len);

    static const char* __tempDirectory;
    static const char* __sessionId;
    static const char* __appToken;
    static const char* __appVersion;
    static const char* __appName;
    static const char* __buildIdentifier;
    static const char* __orientation;
    static const char* __memoryUsage;
    static const char* __memorySize;
    static const char* __modelNumber;
    uint64_t           __diskFree;
    uint64_t           __accountId;
    uint64_t           __agentId;
    static const char* __diskSize;
    static const char* __networkConnectivity;
    static const char* __sessionStartTime;
    static const char* __build;
    
    void NRMA_setAgentId(uint64_t agentId)
    {
        __agentId = agentId;
    }

    uint64_t NRMA_getAgentId() {
        return __agentId;
    }

    void NRMA_setAccountId(uint64_t accountId)
    {
        __accountId = accountId;
    }

    uint64_t NRMA_getAccountId()
    {
        return __accountId;
    }

    void NRMA_setSessionId(const char* sessionId) {
        __NRMA_assign_retain((char**)&__sessionId, sessionId);
    }

    const char* NRMA_getSessionId() {
        return __sessionId;
    }

    //AppToken
    
    void NRMA_setTempDir(const char* tempDir)
    {
        __NRMA_assign_retain((char**)&__tempDirectory, tempDir);
    }

    const char* NRMA_getTempDir()
    {
        return __tempDirectory;
    }
    
    void NRMA_setAppToken(const char* appToken)
    {
        __NRMA_assign_retain((char**)&__appToken, appToken);
    }
    
    const char* NRMA_getAppToken()
    {
        return __appToken;
    }
    
    //AppVersion
    void NRMA_setAppVersion(const char* appVersion)
    {
        __NRMA_assign_retain((char**)&__appVersion, appVersion);
    }
    
    const char* NRMA_getAppVersion()
    {
        return __appVersion;
    }
    
    //AppName
    void NRMA_setAppName(const char* appName)
    {
        __NRMA_assign_retain((char**)&__appName, appName);
    }
    
    const char* NRMA_getAppName()
    {
        return __appName;
    }
    
    //BuildIdentifier
    void NRMA_setBuildIdentifier(const char* buildIdentifier)
    {
        __NRMA_assign_retain((char**)&__buildIdentifier, buildIdentifier);
    }
    
    const char* NRMA_getBuildIdentifier()
    {
        return __buildIdentifier;
    }
    
    //orientation
    void NRMA_setOrientation(const char* orientation)
    {
        __NRMA_assign_retain((char**)&__orientation, orientation);
    }
    
    const char* NRMA_getOrientation()
    {
        return __orientation;
    }
    
    //memoryUsage
    void NRMA_setMemoryUsage(const char* memoryUsage)
    {
        __NRMA_assign_retain((char**)&__memoryUsage, memoryUsage);
    }
    
    const char* NRMA_getMemoryUsage()
    {
        return __memoryUsage;
    }
    
    //memorySize
    void NRMA_setMemorySize(const char* memorySize)
    {
        __NRMA_assign_retain((char**)&__memorySize, memorySize);
    }
    
    const char* NRMA_getMemorySize()
    {
        return __memorySize;
    }
    
    //DiskUsage
    
    void NRMA_setDiskSize(const char* diskSize)
    {
        __NRMA_assign_retain((char**)&__diskSize,diskSize);
    }
    
    const char* NRMA_getDiskSize()
    {
        return __diskSize;
    }
    
    void NRMA_setDiskFree(uint64_t diskFree)
    {
        __diskFree = diskFree;
        //__NRMA_assign_retain((char**)&__diskFree ,diskFree );
    }
    
    uint64_t NRMA_getDiskFree()
    {
        return __diskFree;
    }
    
    //NetworkConnectivity
    
    void NRMA_setNetworkConnectivity(const char* networkConnectivity)
    {
        __NRMA_assign_retain((char**)&__networkConnectivity ,networkConnectivity );
    }
    
    const char* NRMA_getNetworkConnectivity()
    {
        return __networkConnectivity;
    }


void NRMA_setBuild(const char* buildNumber)
{
    __NRMA_assign_retain((char**)&__build, buildNumber);
}

const char* NRMA_getBuild()
{
    return __build;
}

//SessionStartTime
    void NRMA_setSessionStartTime(const char* sessionStartTime)
    {
        __NRMA_assign_retain((char**)&__sessionStartTime,sessionStartTime);
    }
    
    const char* NRMA_getSessionStartTime()
    {
        return __sessionStartTime;
    }
    
    //

    void __NRMA_assign_retain(char** dest, const char* src) {
        unsigned long len = strlen(src);
        if (src == NULL) {
            return;
        }
        char* heapChar = malloc(sizeof(char)*(len+1));
        if (heapChar == NULL) {
            //malloc error *shrug*
            return;
        }
        strncpy(heapChar, src, len);
        heapChar[len] = '\0'; //added null-zero to str
        if ((*dest) != NULL) {
            free((void*)(*dest));
        }
        (*dest) = (char*)heapChar;
    }

    void NRMA__freeMetaData()
    {
        free((void*)__sessionId);
        __sessionId=NULL;
        free((void*)__tempDirectory);
        __tempDirectory=NULL;
        free((void*)__appToken);
        __appToken=NULL;
        free((void*)__appVersion);
        __appVersion=NULL;
        free((void*) __appName);
        __appName=NULL;
        free((void*)__buildIdentifier);
        __buildIdentifier=NULL;
        free((void*) __orientation);
        __orientation=NULL;
        free((void*)__memoryUsage);
        __memoryUsage=NULL;
        free((void*)__memorySize);
        __memorySize=NULL;
        free((void*)__modelNumber);
        __modelNumber=NULL;
//        free((void*)__diskFree),__diskFree=NULL;
        free((void*)__diskSize);
        __diskSize=NULL;
        free((void*)__networkConnectivity);
        __networkConnectivity=NULL;
        free((void*)__sessionStartTime);
        __sessionStartTime=NULL;
    }
    
    void NRMA_freeInteractionHistoryList() {
        NRMAInteractionHistoryNode* root = NRMA__getInteractionHistoryList();
        while (root != NULL) {
            if (root->name != NULL) {
                free((void *)root->name);
                root->name = NULL;
            }
            
            NRMAInteractionHistoryNode* temp = root;
            root = root->next;
            free((void *)temp);
        }
    }
    
    void NRMA_freeExceptionData() {
        NRMA__freeMetaData();
        NRMA_freeInteractionHistoryList();
    }
    
    int NRMA_writeCharValue(int fd, const char *name, const char *value) {
        if (value == NULL)
            return 0;
        
        unsigned long nameLen = strlen(name);
        unsigned long valueLen = strlen(value);
        
        ssize_t ret;
        ret = NRMA_write(fd, (void *)name, nameLen);
        if (ret != nameLen)
            return -1;
            
        ret = NRMA_write(fd, ":", 1);
        if (ret != 1)
            return -1;
        
        ret = NRMA_write(fd, (void *)value, valueLen);
        if (ret != valueLen)
            return -1;
        
        ret = NRMA_write(fd, "\n", 1);
        if (ret != 1)
            return -1;
        
        return 0;
    }
    
    int NRMA_writeUInt64Value(int fd, const char *name, uint64_t value) {
         unsigned long nameLen = strlen(name);
        unsigned long valueSize = sizeof(value);
        
        ssize_t ret;
        ret = NRMA_write(fd, (void *)name, nameLen);
        if (ret != nameLen)
            return -1;
            
        ret = NRMA_write(fd, ":", 1);
        if (ret != 1)
            return -1;
        
        ret = NRMA_write(fd, &value, valueSize);
        if (ret != valueSize)
            return -1;
        
        ret = NRMA_write(fd, "\n", 1);
        if (ret != 1)
            return -1;
        
        return 0;
    }
    
    const char *NRMA_createTempFileName() {
        const char *tempDir = NRMA_getTempDir();
        
        unsigned long fileNameLen = strlen(tempDir) + strlen(kNRMAMetaFileName) + 1;
        
        char *fileName = (char *)malloc(fileNameLen);
        if (fileName == NULL) {
            return NULL;
        }
        
        strncat(fileName, tempDir, strlen(tempDir));
        strncat(fileName, kNRMAMetaFileName, strlen(kNRMAMetaFileName));
        
        return fileName;
    }
    
    void NRMA_writeMetaValues(int fd) {
        if(NRMA_writeCharValue(fd, kNRMAMetaKey_AppName, NRMA_getAppName()) == -1)
            return;
        
        if(NRMA_writeCharValue(fd, kNRMAMetaKey_AppToken, NRMA_getAppToken()) == -1)
            return;
      
        if(NRMA_writeCharValue(fd, kNRMAMetaKey_AppVersion, NRMA_getAppVersion()) == -1)
            return;

        if(NRMA_writeCharValue(fd, kNRMAMetaKey_Build, NRMA_getBuild()) == -1)
            return;

        if(NRMA_writeCharValue(fd, kNRMAMetaKey_BuildId, NRMA_getBuildIdentifier()) == -1)
            return;
      
        if(NRMA_writeCharValue(fd, kNRMAMetaKey_MemoryUse, NRMA_getMemoryUsage()) == -1)
            return;

        if (NRMA_writeCharValue(fd, kNRMAMetaKey_ModelNumber, NRMA_getModelNumber()) == -1)
            return;

        if(NRMA_writeCharValue(fd, kNRMAMetaKey_Orientation, NRMA_getOrientation()) == -1)
            return;
      
        if(NRMA_writeCharValue(fd, kNRMAMetaKey_NetworkConnectivity, NRMA_getNetworkConnectivity()) == -1)
            return;
       
        if(NRMA_writeCharValue(fd, kNRMAMetaKey_SessionStartTime, NRMA_getSessionStartTime()) == -1)
            return;
       
        if(NRMA_writeUInt64Value(fd, kNRMAMetaKey_DiskFree, NRMA_getDiskFree()) == -1)
            return;
       
        if(NRMA_writeUInt64Value(fd, kNRMAMetaKey_AccountId, NRMA_getAccountId()) == -1)
            return;
       
        if(NRMA_writeUInt64Value(fd, kNRMAMetaKey_AgentId, NRMA_getAgentId()) == -1)
            return;

        if(NRMA_writeCharValue(fd, kNRMAMetaKey_Session, NRMA_getSessionId()) == -1)
            return;
     }
    
    void NRMA_writeNRMeta(siginfo_t *info, ucontext_t *uap, void *context)
    {
        const char *tempFileName = NRMA_createTempFileName();
        if (tempFileName == NULL) {
            return;
        }
        
        int fd = open(tempFileName, O_CREAT | O_TRUNC | O_WRONLY, 0755);

        free((void *)tempFileName);
        tempFileName = NULL;

        if (fd == -1) {
            //sad day.
            return;
        }
        NRMA_writeMetaValues(fd);
        NRMA_writeInteractionHistory(fd);
        NRMA_writeCrashTime(fd);

        close(fd);

        NRMA_freeExceptionData();
    }
    
    void NRMA_writeInteractionHistory(int fd)
    {
        NRMAInteractionHistoryNode* root = NRMA__getInteractionHistoryList();
        NRMA__setInteractionList(NULL);

        unsigned long txnKeyLen = strlen(kNRMAMetaKey_Transactions);
        ssize_t ret;
        
        ret = NRMA_write(fd, kNRMAMetaKey_Transactions, txnKeyLen);
        if (ret != txnKeyLen)
            return;
        
        ret = NRMA_write(fd, ":", 1);
        if (ret != 1)
            return;
        
        while (root != NULL) {
           const char* name = root->name;
            size_t len = 0;
            if (name != NULL && (len = strlen(name)) > 0) {
                if(NRMA_write(fd, (void*)name, len) != len)
                    return;

                if(NRMA_write(fd, ";", 1) != 1)
                    return;
                
                ret = NRMA_write(fd, (void*)&(root->timestampMillis), sizeof(root->timestampMillis));
                if(ret != sizeof(root->timestampMillis))
                    return;
            }
            root = root->next;
        }
        NRMA_write(fd, "\n", 1);
    }
    
    void NRMA_writeCrashTime(int fd) {
        time_t t;
        time(&t); //use time(), it's fast (~4 cycles).
        // if we take too long calculating the time the app will terminate.
        NRMA_writeUInt64Value(fd, kNRMAMetaKey_CrashTime, t+1); //add 1 second due to loss of ms accuracy. this makes all calculated values less goofy.
    }

//not async safe, don't call in crash handler.
//this is now only called on harvest before.

    void NRMA_updateModelNumber()
    {

        NSString* model = [NewRelicInternalUtils deviceModel];

        if ([model length]) {
            __NRMA_assign_retain((char**)&__modelNumber, model.UTF8String);
        }

        return;
    }

    const char* NRMA_getModelNumber()
    {
        return __modelNumber;
    }

    void NRMA_updateDiskUsage()
    {
        struct statfs mystat;

        int result = statfs("/", &mystat);

        uint64_t diskSize = 0;
        uint64_t diskFree = 0;
        if (result == 0) {
            diskSize = ((uint64_t)mystat.f_blocks * (uint64_t)mystat.f_bsize);
            diskFree = ((uint64_t)mystat.f_bfree * (uint64_t)mystat.f_bsize);
        }

        NRMA_setDiskFree(diskFree);
    }

    ssize_t NRMA_write(int fd, void* data, size_t len)
    {
        const void* tmpPtr;
        size_t left;
        ssize_t written = 0;

        tmpPtr = data;
        left = len;
        while (left > 0) {
            if ((written = write(fd,tmpPtr,left)) <= 0) {
                if (errno == EINTR) {
                    written = 0;
                } else {
                    return -1;
                }
            }
            left -= written;
            tmpPtr += written;
        }
        return written;
    }


#ifdef __cplusplus
}
#endif // extern "C" {
