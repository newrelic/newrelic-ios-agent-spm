    //
//  NRLogger.m
//  NewRelicAgent
//
//  Created by Jonathan Karon on 10/9/12.
//  Copyright (c) 2012 New Relic. All rights reserved.
//

#import "NRLogger.h"
#import "NewRelicInternalUtils.h"
#import "NRMAJSON.h"

NRLogger *_nr_logger = nil;

@interface NRLogger()
- (void)addLogMessage:(NSDictionary *)message;
- (void)setLogLevels:(unsigned int)levels;
- (void)setLogTargets:(unsigned int)targets;
- (void)clearLog;
@end

@implementation NRLogger

+ (NRLogger *)logger {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _nr_logger = [[NRLogger alloc] init];
    });
    return _nr_logger;
}

+ (void)log:(unsigned int)level
     inFile:(NSString *)file
     atLine:(unsigned int)line
   inMethod:(NSString *)method
withMessage:(NSString *)message {

    NRLogger *logger = [NRLogger logger];
    BOOL shouldLog = NO;
    @synchronized(logger) {
        shouldLog = (logger->logLevels & level) != 0;
    }

    if (shouldLog) {
        [logger addLogMessage:[NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithUnsignedInt:level], NRLogMessageLevelKey,
                               file, NRLogMessageFileKey,
                               [NSNumber numberWithUnsignedInt:line], NRLogMessageLineNumberKey,
                               method, NRLogMessageMethodKey,
                               [[[NSDate alloc] init] description], NRLogMessageTimestampKey,
                               message, NRLogMessageMessageKey,
                               nil]];
    }
}

+ (NRLogLevels) logLevels {
    return [[NRLogger logger] logLevels];
}

+ (void)setLogLevels:(unsigned int)levels {
    [[NRLogger logger] setLogLevels:levels];
}

+ (void)setLogTargets:(unsigned int)targets {
    [[NRLogger logger] setLogTargets:targets];
}

+ (NSString *)logFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    if (basePath) {
        return [[basePath stringByAppendingPathComponent:@"newrelic"] stringByAppendingPathComponent:@"log.json"];
    }
    NSLog(@"NewRelic: No NSDocumentDirectory found, file logging will not be available.");
    return nil;
}

+ (void)clearLog {
    [[NRLogger logger] clearLog];
}


#pragma mark -- internal


- (id)init {
    self = [super init];
    if (self) {
        self->logLevels = NRLogLevelError | NRLogLevelWarning;
        self->logTargets = NRLogTargetConsole;
        self->logFile = nil;
    }
    return self;
}

- (void)dealloc {
    @synchronized(self) {
        if (self->logFile) {
            [self->logFile closeFile];
            self->logFile = nil;
        }
    }
}

- (void)addLogMessage:(NSDictionary *)message {
    // the static method checks the log level before we get here...

    @synchronized(self) {
        if (self->logTargets & NRLogTargetConsole) {
            NSLog(@"NewRelic(%@,%p):\t%@:%@\t%@\n\t%@",
                  [NewRelicInternalUtils agentVersion],
                  [NSThread currentThread],
                  [message objectForKey:NRLogMessageFileKey],
                  [message objectForKey:NRLogMessageLineNumberKey],
                  [message objectForKey:NRLogMessageMethodKey],
                  [message objectForKey:NRLogMessageMessageKey]);
        }
        if (self->logTargets & NRLogTargetFile) {
            NSData *json = [self jsonDictonary:message];
            if (json) {
                if ([self->logFile offsetInFile]) {
                    [self->logFile writeData:[NSData dataWithBytes:"," length:1]];
                }
                [self->logFile writeData:json];
            }
        }
    }
}

- (NSData*) jsonDictonary:(NSDictionary*)message
{
    NSString* json = [NSString stringWithFormat:@"{ \n  \"%@\":\"%@\",\n  \"%@\" : \"%@\",\n  \"%@\" : \"%@\",\n  \"%@\" : \"%@\",\n  \"%@\" : \"%@\",\n  \"%@\" : \"%@\"\n}",
                      NRLogMessageLevelKey, [message objectForKey:NRLogMessageLevelKey],
                      NRLogMessageFileKey, [[message objectForKey:NRLogMessageFileKey]stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""],
                      NRLogMessageLineNumberKey,[message objectForKey:NRLogMessageLineNumberKey],
                      NRLogMessageMethodKey,[[message objectForKey:NRLogMessageMethodKey]stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""],
                      NRLogMessageTimestampKey,[[message objectForKey:NRLogMessageTimestampKey]stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""],
                      NRLogMessageMessageKey,[[message objectForKey:NRLogMessageMessageKey]stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];

    return [json dataUsingEncoding:NSUTF8StringEncoding];
}


- (void)setLogLevels:(unsigned int)levels {
    @synchronized(self) {
        unsigned int l = 0;
        switch (levels) {
            case NRLogLevelError:
                l = NRLogLevelError; break;
            case NRLogLevelWarning:
                l = NRLogLevelError | NRLogLevelWarning; break;
            case NRLogLevelInfo:
                l = NRLogLevelError | NRLogLevelWarning | NRLogLevelInfo; break;
            case NRLogLevelVerbose:
                l = NRLogLevelError | NRLogLevelWarning | NRLogLevelInfo | NRLogLevelVerbose; break;
            case NRLogLevelAudit:
                l = NRLogLevelError | NRLogLevelWarning | NRLogLevelInfo | NRLogLevelVerbose | NRLogLevelAudit ; break;
            default:
                l = levels; break;
        }
        self->logLevels = l;
    }
}

    - (NRLogLevels) logLevels {
        return self->logLevels;
    }


- (void)setLogTargets:(unsigned int)targets {
    NSString *fileOpenError = nil;

    @synchronized(self) {
        self->logTargets = targets;
        if (targets & NRLogTargetFile) {
            if (! self->logFile) {
                NSString *path = [NRLogger logFilePath];
                NSString *parent = [path stringByDeletingLastPathComponent];
                NSError *err;
                BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:parent
                                                         withIntermediateDirectories:YES
                                                                          attributes:nil
                                                                               error:&err];
                if (! success) {
                    fileOpenError = [NSString stringWithFormat:@"Cannot create log file directory '%@': %@", parent, [err description]];
                }
                else {
                    if (! [[NSFileManager defaultManager] fileExistsAtPath:path]) {
                        success = [[NSFileManager defaultManager] createFileAtPath:path
                                                                          contents:[[NSData alloc] init]
                                                                        attributes:nil];
                        if (! success) {
                            fileOpenError = [NSString stringWithFormat:@"Cannot create log file '%@'", path];
                        }
                    }
                    if (success) {
                        self->logFile = [NSFileHandle fileHandleForUpdatingAtPath:path];
                        [self->logFile seekToEndOfFile];
                        if (! self->logFile) {
                            success = NO;
                            fileOpenError = [NSString stringWithFormat:@"Cannot write log file '%@'", path];
                        }
                    }
                }

                if (! success) {
                    self->logTargets &= ~NRLogTargetFile;
                }
            }
        }
        else {
            if (self->logFile) {
                [self->logFile closeFile];
                self->logFile = nil;
            }
        }
    }

    if (fileOpenError) {
        if (self->logTargets && self->logLevels) {
            NRLOG_ERROR(@"%@", fileOpenError);
        }
        else {
            NSLog(@"NewRelic: error opening log file %@", fileOpenError);
        }
    }
}

- (void)clearLog {
    @synchronized(self) {
        if (self->logFile) {
            // close the log file if it's open
            [self->logFile closeFile];
            self->logFile = nil;

            // truncate the log file on disk
            NSString *path = [NRLogger logFilePath];
            NSError *err = nil;
            if (! [[NSFileManager defaultManager] removeItemAtPath:path error:&err]) {
                NSLog(@"NewRelic: Unable to truncate log file at '%@'", path);
            }

            // calling setLogTargets: will re-open the file safely
            //   Note: @synchronized is re-entrant, so we don't need to worry about lock contention
            [self setLogTargets:self->logTargets];
        }
    }
}

@end

