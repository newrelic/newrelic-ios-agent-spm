//
// Created by Bryce Buchanan on 3/15/18.
// Copyright (c) 2018 New Relic. All rights reserved.
//

#import "NRMAFileCleanup.h"
#import "NewRelicInternalUtils.h"
#import "NRLogger.h"


@implementation NRMAFileCleanup

+ (void) updateDocFileLocations {
    const NSArray* __oldDocFiles =  @[
            @"attributeDupStore.txt",
            @"attributeDupStore.txt.bak",
            @"eventsDupStore.txt",
            @"eventsDupStore.txt.bak",
            @"persistentAttributeStore.txt",
            @"hexbkup/",
            @"newrelic/"

    ];


    for (NSString* filename in __oldDocFiles) {
        NSArray<NSURL*>* dictArray = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                                            inDomains:NSUserDomainMask];
        NSURL* defaultDocURL = dictArray[0];
        BOOL isDir = NO;

        NSString* filePath = [defaultDocURL.path stringByAppendingPathComponent:filename];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath
                                                 isDirectory:&isDir]){
            NSError* error;
            [[NSFileManager defaultManager] moveItemAtPath:filePath
                                                    toPath:[[NewRelicInternalUtils getStorePath] stringByAppendingPathComponent:filename]
                                                     error:&error];
            if (error) {
                NRLOG_VERBOSE(@"failed to move old file %@ to new storage dir: %@",filename, error.description);
            }
        }
    }
}

@end
