//
//  NRMACrashReportsManager.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/17/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMACrashReportFileManager.h"
//#import "NRMAExceptionReportParser.h"
#import "NRLogger.h"
#import "NRMAExceptionMetaDataStore.h"
#import "NRMACrashDataWriter.h"
#import "NRMACrashDataUploader.h"
@interface NRMACrashReportFileManager ()
@property(assign) PLCrashReporter* crashReporter;
@property(strong) NSFileManager*  fileManager;
@property(strong) NSMutableArray* crashFiles;
@property(strong) NSString*       crashPath;
@end

@implementation NRMACrashReportFileManager

- (instancetype) initWithCrashReporter:(PLCrashReporter*)crashReporter
{
    self = [super init];
    if (self) {
        _crashReporter = crashReporter;
        _fileManager = [[NSFileManager alloc] init];
        _crashFiles  = [[NSMutableArray alloc] init];

        // temporary directory for crashes grabbed from PLCrashReporter
        // highly suspect...
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _crashPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/crashes/"];

        if (![_fileManager fileExistsAtPath:_crashPath]) {
            NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong: 0755]
                                                                   forKey:NSFilePosixPermissions];
            NSError *theError = nil;
            [_fileManager createDirectoryAtPath:_crashPath
                    withIntermediateDirectories:YES
                                     attributes:attributes
                                          error:&theError];
        }
    }
    return self;
}

static NSString* __processLock = @"NRMAProcessLock";

- (void) processReportsWithSessionAttributes:(NSDictionary*)attributes
                             analyticsEvents:(NSArray*)events
{
    NSError* error = nil;
    if (!_crashReporter) {
        NRLOG_VERBOSE(@"Attempted to process crash reports with an uninitialized crash reporter.");
        return;
    }
    @synchronized(__processLock) {
        // Try loading the crash report
        NRLOG_VERBOSE(@"Processing crash reports.");
        NSData *crashData = [[NSData alloc] initWithData:[_crashReporter loadPendingCrashReportDataAndReturnError:&error]];

        if (crashData == nil) {
            NRLOG_ERROR(@"Could not load pending crash report: %@",[error localizedDescription]);
            return;
        }

        PLCrashReport* report = [[PLCrashReport alloc] initWithData:crashData error:&error];

        if (report == nil) {
            NRLOG_VERBOSE(@"could not parse crash report: %@",error);
            return;
        }

        NSDictionary* metadict = [self getMetaData];


        if (metadict.count == 0) {
            NRLOG_ERROR(@"Unable to write crash report: missing meta-data.");
        } else {
            [NRMACrashDataWriter writeCrashReport:report
                                     withMetaData:metadict
                                sessionAttributes:attributes
                                  analyticsEvents:events];
        }
    }

    [_crashReporter purgePendingCrashReport];
}

- (NSDictionary*) getMetaData
{

    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    const char* tempDir = NRMA_getTempDir();
    NSString* path = [NSString stringWithFormat:@"%s/%@",tempDir,@"/metadata.nr.crash"];
    NSData* data = [NSData dataWithContentsOfFile:path];
    
    if (data == nil) {
        return dict;
    }
    
    NSUInteger dataLength = data.length;
    const void* dataBuf = [data bytes];

    int offset = 0;
    while (offset < dataLength && *((char*)dataBuf+offset) != '\0') {

        NSError* error = nil;
        NSString* key = [self stringFromBuf:dataBuf offset:&offset terminal:':' error:&error];
        if (error) {
            //failed to read buf
            return dict;
        }

        id value = nil;
        if ([key isEqualToString:@kNRMAMetaKey_DiskFree]||
            [key isEqualToString:@kNRMAMetaKey_AccountId]||
            [key isEqualToString:@kNRMAMetaKey_AgentId] ||
            [key isEqualToString:@kNRMAMetaKey_CrashTime]) {
            NSError* error = nil;
            int64_t int64 = [self int64FromBuf:dataBuf
                                  bufsize:dataLength
                                   offset:&offset
                                    error:&error];
            offset+=1; //jump the /n
            if (error) {
                return dict;
            }

            value = [NSNumber numberWithLongLong:int64];

        } else if ([key isEqualToString:[NSString stringWithFormat:@"%s", kNRMAMetaKey_Transactions]]){
            value = [[NSMutableArray alloc] init];
            do {
                NSError* error = nil;
                NSString* name = [self stringFromBuf:dataBuf
                                              offset:&offset
                                            terminal:';'
                                               error:&error];
                if (error) break; //grabbing name when wrong

                 uint64_t timestamp = [self int64FromBuf:dataBuf
                                                     bufsize:dataLength
                                                      offset:&offset
                                                       error:&error];
                if (error) break; //ran over buffer!

                if (name != nil) {
                    [value addObject:[NSArray arrayWithObjects:[NSNumber numberWithLongLong:timestamp],name,nil]];
                }
            } while (*((char*)dataBuf+offset)!='\n' && offset < dataLength);
            offset += 1;
        } else {

            NSError* error = nil;
            value = [self stringFromBuf:dataBuf offset:&offset terminal:'\n' error:&error];
            if (error) {
                return dict; //failed to read
            }
        }

        if (value != nil) {
            [dict setValue:value forKey:key];
        }
    }

    return dict;
}


- (uint64_t) int64FromBuf:(const void*)buf bufsize:(uint64_t)bufsize offset:(int*)offset error:(NSError* __autoreleasing *)error
{
    if (((*offset) + sizeof(uint64_t)) > bufsize) {
        if (error) {
            (*error) = [NSError errorWithDomain:@"buffer overflow" code:1 userInfo:nil];
        }
        return 0;
    }
    uint64_t timestamp = *((int64_t*)(buf+(*offset)));
    (*offset) += sizeof(timestamp);

    return timestamp;
}

- (NSString*) stringFromBuf:(const void*)buf offset:(int*)offset terminal:(char)terminal error:(NSError* __autoreleasing *)error
{
    NSRange range = [self rangeOfBytesFromData:buf+(*offset) toCharacter:terminal];
    if (range.location == NSNotFound) {
        if (error) {
            (*error) = [NSError errorWithDomain:@"failed to parse buffer" code:1 userInfo:nil];
        }
        return nil;
    }

    NSString* string = [[NSString alloc] initWithBytes:buf+(*offset)
                                              length:range.length
                                            encoding:NSASCIIStringEncoding];
    (*offset) += range.length + 1;
    return string;
}



- (NSRange) rangeOfBytesFromData:(const void*)data toCharacter:(char)c
{
    int offset = 0;
    char mychar = 0;
    while ((mychar = *((char*)data+offset)) != c) {
        if (mychar == '\0') {
            return NSMakeRange(NSNotFound, 0);
        }
        offset++;
    }

    return NSMakeRange(0, offset);
}

@end

