//
//  NRMAExceptionHandlerManager.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/17/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NRMAExceptionMetaDataStore.h"

#import "NRMAExceptionHandlerManager.h"
#import "NRMAUncaughtExceptionHandler.h"
#import "NRMACrashReportFileManager.h"
#import "PLCrashNamespace.h"
#import "PLCrashReporter.h"
#import "NRMACrashDataUploader.h"
#import "NRLogger.h"
#import "NRConstants.h"
#import "NRMAMemoryVitals.h"
#import "NewRelicInternalUtils.h"
#import "NRMATaskQueue.h"
#import "NRMAMetric.h"
#import "NRMACrashReporterRecorder.h"

@interface NRMAExceptionHandlerManager  ()
@property(strong) PLCrashReporter* crashReporter;
@property(strong) NRMACrashReportFileManager* reportManager;
@property(strong) NRMAUncaughtExceptionHandler* handler;
@end

@implementation NRMAExceptionHandlerManager
static NRMAExceptionHandlerManager* __manager;
static const NSString* NRMAManagerAccessorLock = @"managerLock";
+ (void) setManager:(NRMAExceptionHandlerManager*)manager
{
    @synchronized(NRMAManagerAccessorLock) {
        if (__manager) {
            [NRMAHarvestController removeHarvestListener:__manager];
        }
        __manager = manager;
        if (manager != nil) {
            [NRMAHarvestController addHarvestListener:__manager];
        }
    }

}

+ (NRMAExceptionHandlerManager*) manager
{
    @synchronized(NRMAManagerAccessorLock) {
        return __manager;
    }
}


+ (void) startHandlerWithLastSessionsAttributes:(NSDictionary*)attributes
                             andAnalyticsEvents:(NSArray*)events
                                  uploadManager:(NRMACrashDataUploader*)uploader {
    NRMA_updateDiskUsage();
    NRMA_updateModelNumber();
    [self setManager:[[NRMAExceptionHandlerManager alloc] initWithLastSessionsAttributes:attributes
                                                                      andAnalyticsEvents:events
                                                                           uploadManager:uploader]];
    [NRMAMemoryVitals memoryUseInMegabytes]; //triggers a memory usage notification
    [[self manager] updateNetworkingStatus];
    [[self manager].handler start];
    [[self manager] fireDelayedProcessing];
}

- (instancetype) initWithLastSessionsAttributes:(NSDictionary*)attributes
                             andAnalyticsEvents:(NSArray*)events
                                  uploadManager:(NRMACrashDataUploader*)uploader {
    self = [super init];
    if (self) {
        self.uploader = uploader;
        [self registerObservers];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryUsageNotification:) name:kNRMemoryUsageDidChangeNotification object:nil];

        //PLCrashReporterSignalHandlerTypeBSD tried and true vs MACH handler...
        //it's recommended to use BSD in production, while MACH can be used in
        //dev is you really want to.
        //first iteration will default to BSD, with no option to change this.
        PLCrashReporterSignalHandlerType signalHandlerType = PLCrashReporterSignalHandlerTypeBSD;

        //we don't want to attempt to symbolicate at runtime due to the possibility of stack corruption
        //as well as it being inaccurate. Let's save it for the server where we have the dsym files!
        //SymboolicationStrategy = PLCrashReporterSymbolicationStrategyNone
        PLCrashReporterConfig *config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType:signalHandlerType
                                                                           symbolicationStrategy:PLCrashReporterSymbolicationStrategyNone];


        _crashReporter = [[PLCrashReporter alloc] initWithConfiguration:config];

        PLCrashReporterCallbacks callback;
        callback.handleSignal = NRMA_writeNRMeta;
        callback.version = 0;


        PLCrashReporterCallbacks* callbacks  = &callback;
        [_crashReporter setCrashCallbacks:callbacks];
        _reportManager = [[NRMACrashReportFileManager alloc] initWithCrashReporter:_crashReporter];

        if ([_crashReporter hasPendingCrashReport]) {
            //process pending crash reports
            //this would possible mean the last session ended in a crash
            [_reportManager processReportsWithSessionAttributes:attributes
                                                analyticsEvents:events];

            [self.uploader uploadCrashReports];
        }

        self.handler = [[NRMAUncaughtExceptionHandler alloc] initWithCrashReporter:_crashReporter];
    }
    return self;
}

- (void) registerObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fireDelayedProcessing)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    //impelement notification on network is available
}


- (void) fireDelayedProcessing
{
    //this prevents from multiple execution of executeDelayedProcessing on instances where
    //both network becomes available and application did become active.
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(executeDelayedProcessing) object:nil];
    [self performSelector:@selector(executeDelayedProcessing) withObject:nil afterDelay:.5];
}

- (void) executeDelayedProcessing
{
    if (![self.handler isActive]) {
        return;
    }
    if (![self.handler isExceptionHandlerValid]) {


        NSArray*(^myblock)(void) = ^NSArray*(void){
            NSMutableArray* list = [[NSMutableArray alloc] init];
            NRMACrashReporterRecorder* crashRecorder = [[NRMACrashReporterRecorder alloc] init];
            if ([crashRecorder isCrashlyticsDefined]) {
                [list addObject:@"Crashlytics"];
            }
            if ([crashRecorder isHockeyDefined]) {
                [list addObject:@"HockeyApp"];
            }
            if ([crashRecorder isCrittercismDefined]) {
                [list addObject:@"Crittercism"];
            }
            if ([crashRecorder isTestFlightDefined]) {
                [list addObject:@"TestFlight"];
            }
            if ([crashRecorder isFlurryDefined]) {
                [list addObject:@"Flurry"];
            }
            return list;
        };

        NSArray* crashFrameworkList = myblock();
        NSString* errorMessage = @"Error: The New Relic exception handler has been replaced. This may result in crashes no longer reporting to New Relic.";
        if ([crashFrameworkList count]) {
            errorMessage = [errorMessage stringByAppendingString:[NSString stringWithFormat:@"\n\tWe've detected the following framework(s) that may be responsible for replacing the uncaught exception handler:\n\t\t%@",[crashFrameworkList componentsJoinedByString:@"\n\t\t"]]];
        }
        NRLOG_ERROR(@"%@",errorMessage);
        [NRMATaskQueue queue:[[NRMAMetric alloc] initWithName:kNRMAExceptionHandlerHijackedMetric 
                                                        value:@1
                                                        scope:nil]];
    }

    //crash file manager gather and transmit to crash harvester
}


- (void) onHarvestBefore
{
    NRMA_updateDiskUsage();
    [NRMAMemoryVitals memoryUseInMegabytes]; //triggers a memory usage notification

    [self updateNetworkingStatus];
}

- (void) updateNetworkingStatus
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,
                                             0),
                   ^{
                       switch([NewRelicInternalUtils networkStatus]){
                           case NotReachable:
                               NRMA_setNetworkConnectivity("Not Reachable");
                               break;
                           case  ReachableViaWiFi:
                               NRMA_setNetworkConnectivity("WiFi");
                               break;
                           case ReachableViaWWAN:
                               NRMA_setNetworkConnectivity("Cell");
                               break;
                           default:
                               NRMA_setNetworkConnectivity("Unknown");
                               break;
                       }
                   });
}

static const NSString* __memoryUsageLock = @"Lock";
- (void) didReceiveMemoryUsageNotification:(NSNotification*)memoryUsageNotification
{
    NSString* memoryUsageMB = (NSString*)memoryUsageNotification.object;

    if ([memoryUsageMB isKindOfClass:[NSString class]] && memoryUsageMB.length) {
        //NSNotifications are not thread safe so we need to synchronize before we
        //start setting things.
        @synchronized(__memoryUsageLock) {
            NRMA_setMemoryUsage(memoryUsageMB.UTF8String);
        }
    }
}

@end
