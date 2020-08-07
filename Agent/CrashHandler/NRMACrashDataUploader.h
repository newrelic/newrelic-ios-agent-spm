//
//  NRMACrashDataUploader.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 6/18/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAConnection.h"

#define kNRMAMaxCrashUploadRetry 3
@interface NRMACrashDataUploader : NRMAConnection
{
    NSFileManager* _fileManager;
    NSString* _crashCollectorHost;
    BOOL _useSSL;
}

- (void) uploadCrashReports;

- (instancetype) initWithCrashCollectorURL:(NSString*)url
                          applicationToken:(NSString*)token
                     connectionInformation:(NRMAConnectInformation*)connectionInformation
                                    useSSL:(BOOL)useSSL;
@end

