//
//  NRMAUUIDStore.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 12/2/15.
//  Copyright © 2015 New Relic. All rights reserved.
//

#import "NRMAUUIDStore.h"
#import "NRLogger.h"
#import <UIKit/UIKit.h>

@interface  NRMAUUIDStore ()
@property(copy) NSString* filename;
@property(strong) NSString* UUID;
@end

@implementation NRMAUUIDStore

- (instancetype) initWithFilename:(NSString* const)filename {
    self = [super init];
    if (self) {
        self.filename = filename;
    }
    return self;
}

- (NSString*) storedUUID
{
    if (self.UUID == nil) {
        self.UUID = [self fetchStoredUDID];
    }
    return self.UUID;
}

- (NSString*) fetchStoredUDID {
    if (![self storeExists]) {
        return nil;
    }
    NSError* error = nil;
     NSString* fileContents = [NSString stringWithContentsOfFile:[[self storePath] stringByAppendingFormat:@"/%@",self.filename]
                                     encoding:NSUTF8StringEncoding
                                        error:&error];
    if (error != nil) {
        NRLOG_ERROR(@"failed to load file (%@): %@",[[self storePath] stringByAppendingFormat:@"/%@",self.filename],error.description);
    }
    return fileContents;
}

- (BOOL) storeExists {
    return [[NSFileManager defaultManager] fileExistsAtPath:[[self storePath] stringByAppendingFormat:@"/%@",self.filename]];
}


- (NSString*) storePath {
#if TARGET_OS_TV
    //tvOS doesn't support the Application Support dir. The cache dir is the next best thing (and is used by the crash reporter, which means it should work O.K.)
    NSArray *paths = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    NSURL *cacheDir = paths[0];
    return cacheDir.path;
#else
    return [NSHomeDirectory() stringByAppendingString:@"/Library/Application Support"];
#endif
}

- (BOOL) storeUUID:(NSString *)UUID  {
    return [self store:UUID
                inFile:self.filename];
}

- (BOOL) store:(NSString*)UDID
        inFile:(const NSString*)fileName {
    NSError* error = nil;
    if ([self storeExists]) {

        [[NSFileManager defaultManager] removeItemAtPath:[[self storePath] stringByAppendingFormat:@"/%@",fileName]
                                                   error:&error];
        if ( error != nil) {
            NRLOG_ERROR(@"failed to remove file (%@): %@",[[self storePath] stringByAppendingFormat:@"/%@",fileName],error.description);
            return NO;
        }
    } else {
        [[NSFileManager defaultManager] createDirectoryAtPath:[self storePath]
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if ( error != nil) {
            NRLOG_ERROR(@"failed to create directory (%@): %@",[self storePath],error.description);
            return NO;
        }
    }
    return [[NSFileManager defaultManager] createFileAtPath:[[self storePath] stringByAppendingFormat:@"/%@",fileName]
                                                   contents:[UDID dataUsingEncoding:NSUTF8StringEncoding]
                                                 attributes:nil];
}

- (void) removeStore {

    NSError* error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[[self storePath] stringByAppendingFormat:@"/%@",self.filename]
                                               error:nil];
    if ( error != nil) {
        NRLOG_ERROR(@"failed to remove file (%@): %@",[[self storePath] stringByAppendingFormat:@"/%@",self.filename],error.description);
    }
}

@end
