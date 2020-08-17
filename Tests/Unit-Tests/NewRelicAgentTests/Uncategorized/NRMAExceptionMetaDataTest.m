//
//  NRMAExceptionMetaDataTest.m
//  NewRelicAgent
//
//  Created by Jared Stanbrough on 5/28/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAExceptionMetaDataStore.h"
#include <sys/utsname.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>

@interface NRMAExceptionMetaDataTest : XCTestCase

@end

@implementation NRMAExceptionMetaDataTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test_NRMA_writeNRMeta
{

    NRMA_setTempDir("./");

    const char *tempFile = NRMA_createTempFileName();



    char buff[500];

    getcwd(buff, 500);
    
    NSLog(@"tempfile path: %s",tempFile);

    const char* machineName = nil;
    struct utsname sysName;
    int error = uname(&sysName);
    if (error == 0) {
        machineName = sysName.machine;
    }

    remove(tempFile);


    NRMA_setAppName("test");
    NRMA_setAppToken("abc123");
    NRMA_setAppVersion("1.0");
    NRMA_setBuildIdentifier("01234");
    NRMA_setMemoryUsage("128");
    NRMA_updateModelNumber();
    NRMA_setOrientation("portrait");
    NRMA_setNetworkConnectivity("wifi");
    NRMA_setSessionStartTime("1234");
    NRMA_setDiskFree(123456);
    NRMA_setAccountId(2);
    NRMA_setAgentId(1);
    
    NRMA_writeNRMeta(NULL, NULL, NULL);


    int fd = open(tempFile, O_RDONLY, 0655);
    if (fd == -1) {
        NSLog(@"%d : %s",errno, strerror(errno));
        return;
    }
    XCTAssertFalse(fd == -1, @"can't open tempfile: %s", tempFile);
    
    struct stat tempStat;
    ssize_t err = stat(tempFile, &tempStat);
    XCTAssertFalse(err < 0, @"Failed to stat temp file");

    char *metaData = (char *)malloc((unsigned long)tempStat.st_size);
    XCTAssertFalse(metaData == NULL, @"Failed to alloc space for crash metadata");

    err = read(fd, metaData, (size_t)tempStat.st_size);
    XCTAssertTrue(err == tempStat.st_size, @"Failed to sizread all crash metadata");
//@\xe2\x01
//    const char* expectedData = [NSString stringWithFormat:].UTF8String;
    char buf[256];
    snprintf(buf, 255, "appname:test\napptoken:abc123\nappversion:1.0\nbuildidentifier:01234\nmemoryusage:128\nmodelnumber:%s\norientation:portrait\nnetworkconnectivity:wifi\nsessionstarttime:1234\ndiskfree:@\xe2\x01",machineName);
    XCTAssertTrue(strcmp(metaData,buf) == 0, @"Expecting different meta data");
    
    free((void *)metaData);
    free((void *)tempFile);
}

@end
