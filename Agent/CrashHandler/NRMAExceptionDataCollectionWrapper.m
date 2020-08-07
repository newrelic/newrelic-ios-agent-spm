//
//  NRMAExceptionDataCollector.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/1/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//


#import <UIKit/UIKit.h>

#import "NRMAExceptionDataCollectionWrapper.h"
#import "NRMAExceptionMetaDataStore.h"
#import "NRMAReachability.h"
#import <sys/stat.h>


static NRMAExceptionDataCollectionWrapper* __wrapper;

@implementation NRMAExceptionDataCollectionWrapper

- (instancetype) init
{
    self = [super init];
    if (self) {

    }
    return self;
}


+ (NRMAExceptionDataCollectionWrapper*) singleton {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __wrapper = [[NRMAExceptionDataCollectionWrapper alloc] init];
    });

    return __wrapper;
}


+ (void) startCrashMetaDataMonitors
{
    [[[self class] singleton] getDiskUsage];
    [[[self class] singleton] beginMonitoringOrientation];
    [[[self class] singleton] beginMonitoringMemoryUsage];

}

- (void) beginMonitoringMemoryUsage
{

}

#pragma mark - orientation observation
- (void) beginMonitoringOrientation
{
#if !TARGET_OS_TV
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
#endif
}

- (void) endMonitoringOrientation
{
#if !TARGET_OS_TV
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
#endif
}

- (void) deviceDidChange:(NSNotification*) notification
{
#if !TARGET_OS_TV
    if( UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)){
        NRMA_setOrientation("2");
    } else if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
        NRMA_setOrientation("1");
    }
#endif
}

#pragma mark - disk usage fetch
- (void) getDiskUsage
{
//    struct statfs mystat;
//
//    int result = statfs("/", &mystat);
//
//    {
//        NSError* error;
//        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSUserDirectory, NSAllDomainsMask, NO);
//        NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths firstObject] error:&error];
//    }
//
//    uint64_t diskSize = -1;
//    uint64_t diskFree = -1;
//    if (result == 0) {
//        diskSize = ((uint64_t)mystat.f_blocks * (uint64_t)mystat.f_bsize);
//        diskFree = ((uint64_t)mystat.f_bfree * (uint64_t)mystat.f_bsize);
//    }
//    NRMA_setDiskFree([NSString stringWithFormat:@"%lld",diskFree].UTF8String);
//    NRMA_setDiskSize([NSString stringWithFormat:@"%lld",diskSize].UTF8String);
//
//
//    return;
}

#pragma mark external facing setters
// Store Network Status
+ (void) storeNetworkStatus:(NRMANetworkStatus)status
{
    NRMA_setNetworkConnectivity([[self class] enumToString:status].UTF8String);
}

+ (NSString*) enumToString:(NRMANetworkStatus)status
{
    switch (status) {
        case ReachableViaWiFi:
            return @"wifi";
            break;
        case ReachableViaWWAN:
            return @"cell";
        case NotReachable:
        default:
            return @"none";
            break;
    }
}
@end
