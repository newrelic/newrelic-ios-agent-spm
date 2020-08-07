//
//  NRMACrashDataUploader.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 6/18/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAConnection.h"
#import "NRMACrashDataUploader.h"
#import "NRMAExceptionhandlerConstants.h"
#import "NRLogger.h"
#import "NewRelicAgentInternal.h"
#import "NRMAHarvestController.h"
#import "NRMATaskQueue.h"

@implementation NRMACrashDataUploader

- (instancetype) initWithCrashCollectorURL:(NSString*)url
                          applicationToken:(NSString*)token
                     connectionInformation:(NRMAConnectInformation*)connectionInformation
                                    useSSL:(BOOL)useSSL
{
            self = [super init];
            if (self) {
                _fileManager = [NSFileManager defaultManager];
                self.applicationToken = token;
                self.applicationVersion = connectionInformation.applicationInformation.appVersion;
                _crashCollectorHost = url;
                _useSSL = useSSL;
            }
            return self;
        }

- (NSArray*) crashReportURLs:(NSError* __autoreleasing*)error
{
    NSString* reportPath = [NSString stringWithFormat:@"%@/%@",NSTemporaryDirectory(),kNRMA_CR_ReportPath];

    NSArray* fileList = [_fileManager contentsOfDirectoryAtURL:[NSURL fileURLWithPath:reportPath]
                                   includingPropertiesForKeys:nil
                                                      options:NSDirectoryEnumerationSkipsHiddenFiles| NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                        error:error];

    NSMutableArray* crashReports = [NSMutableArray new];
    for (NSURL* url in fileList) {
        if ([url.pathExtension isEqualToString:kNRMA_CR_ReportExtension]) {
            [crashReports addObject:url];
        }
    }

    return crashReports;
}


- (void) uploadCrashReports
{
    NSError* error = nil;
    NSArray* reportURLs = [self crashReportURLs:&error];
    if ([reportURLs count] <= 0) {
        if (error) {
            NRLOG_VERBOSE(@"failed to fetch crash reports: %@",error.description);
        } else {
            NRLOG_VERBOSE(@"Currently no crash files to upload.");
        }
        return;
    }

    for (NSURL* fileURL in reportURLs) {
        [self uploadFileAtPath:fileURL];
    }
}

- (void) uploadFileAtPath:(NSURL*)path
{
    if (!_crashCollectorHost.length) {
        NRLOG_ERROR(@"Crash collector address was not set. Unable to upload crash.");
        return;
    }

    if (path == nil) {
        NRLOG_ERROR(@"CrashData path was not set. Unable to upload crash.");
        return;
    }

    //start tracking file upload attempts.
    if (![self shouldUploadFileWithUniqueIdentifier:path.absoluteString]) {
        NRLOG_VERBOSE(@"Reached upload retry limit for a crash report. Removing crash report: %@",path.absoluteString);
        //supportability Supportability/AgentHealth/Crash/RemovedStale
        [NRMATaskQueue queue:[[NRMAMetric alloc] initWithName:kNRSupportabilityPrefix@"/Crash/RemoveStale"
                                                        value:@1
                                                        scope:nil]];
        [_fileManager removeItemAtURL:path error:nil];
        return;
    }

    NSURLRequest* request = [self buildPostFromFilePath:path.path];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                   if(((NSHTTPURLResponse*)response).statusCode == 200 || ((NSHTTPURLResponse*)response).statusCode == 500) {
                                       NSError* error = nil;
                                       //stop tracking the file's upload attempts.
                                       [self stopTrackingFileUploadWithUniqueIdentifier:path.absoluteString];
                                       BOOL didRemoveFile = [_fileManager removeItemAtURL:path error:&error];

                                       if (error) {
                                           NRLOG_ERROR(@"Failed to remove crash file :%@, %@",path.path, error.description);
                                       } else if (!didRemoveFile) {
                                           NRLOG_ERROR(@"Failed to remove crash file. Error unknown.");
                                       }
                                   } else {
                                       NRLOG_VERBOSE(@"failed to upload crash log: %@, to try again later.",path.path);
                                   }
                               }
                           }];
}

- (NSURLRequest*) buildPostFromFilePath:(NSString*)path {
    NSMutableURLRequest* request = [super newPostWithURI:[NSString stringWithFormat:@"%@%@/%@",_useSSL?@"https://":@"http://",_crashCollectorHost,kNRMA_CR_CrashCollectorPath]];

    NSInputStream* stream = [[NSInputStream alloc] initWithFileAtPath:path];
    [request setHTTPBodyStream:stream];
    return request;
}

- (void) stopTrackingFileUploadWithUniqueIdentifier:(NSString*)key {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:key];
    [defaults synchronize];
}

- (BOOL) shouldUploadFileWithUniqueIdentifier:(NSString*)key {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSNumber* value = [defaults objectForKey:key];
    if (value != nil) {
        value = @(value.integerValue + 1);
    } else {
        value = @1;
    }

    if (value.integerValue > kNRMAMaxCrashUploadRetry) {
        [self stopTrackingFileUploadWithUniqueIdentifier:key];

        
        return NO;
    }

    [defaults setObject:value forKey:key];
    [defaults synchronize];
    return YES;
}

@end
