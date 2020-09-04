//
//  NewRelicAgentInternal.m
//  NewRelicAgent
//
//  Created by Saxon D'Aubin on 6/12/12.
//  Copyright (c) 2012 New Relic. All rights reserved.
//

#import "NewRelicAgentInternal.h"
#import "NRLogger.h"

#import "NewRelicInternalUtils.h"
#import "NRMAHarvesterConfiguration.h"
#import "NRMAMethodSwizzling.h"
#import "NRMAReachability.h"

#import "NRTimer.h"

#import "NRMAURLSessionOverride.h"

#import "NRMAJSON.h"
#import "NRMANonARCMethods.h"
#import "NRCustomMetrics+private.h"


#import <objc/runtime.h>
#import <execinfo.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CLGeocoder.h>

#import <zlib.h>

#import "NRMANSURLConnectionSupport.h"

#import "NRMAHarvestController.h"
#import "NRMATraceController.h"
#import "NRMAUserActionBuilder.h"

/* Temporarily here for timing call stacks */
#import <assert.h>
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <unistd.h>
#import <objc/runtime.h>

#import "NRMALastActivityTraceController.h"
#import "NRMACrashReporterRecorder.h"
#import "NRMAMetric.h"
#import "NRMATaskQueue.h"
#import "NRMAExceptionHandler.h"
#import "NRMAMethodProfiler.h"
#import "NRMACPUVitals.h"

#import "NRMAExceptionHandlerManager.h"

#import "NRMAExceptionMetaDataStore.h"
#import "NRMAInteractionHistoryObjCInterface.h"
#import "NRMAExceptionDataCollectionWrapper.h"
#import "NRMACrashDataUploader.h"
#import "NRMAExceptionhandlerConstants.h"
#import "NRMAApplicationInstrumentation.h"
#import "NRMAGestureRecognizerInstrumentation.h"
#import "NRMATableViewIntrumentation.h"
#import "NRMACollectionViewInstrumentation.h"

#import "NRMAAppUpgradeMetricGenerator.h"
#import "NRMAAppInstallMetricGenerator.h"
#import "NRMAAnalytics.h"
#import <Analytics/Constants.hpp>
#import "NRMAWKWebViewInstrumentation.h"
#import "NRMAExceptionHandlerStartupManager.h"
#import "NRMAFlags.h"
#import "NRMAUserAction.h"
#import "NRMAUserActionFacade.h"
#import "NRMAFileCleanup.h"
#import "NRMAAppToken.h"

/* Support for teardown and re-setup of the agent within a process lifetime for our test harness
 Enabling this will bypass dispatch_once-style logic and expose more internal state.
 Must be set before calling [NewRelic startWithApplicationToken:...] */
BOOL _NRMAAgentTestModeEnabled = NO;
/* Setting this to YES will force the agent to connect to the collector synchronously. */
BOOL _NRMAAgentSyncConnectEnabled = NO;

/* Allow our host to set the appname and appversion if they aren't in the main bundle 
 Must be set before calling [NewRelic startWithApplicationToken:...] */
NSString* _NRMAAgentApplicationName = nil;
NSString* _NRMAAgentApplicationVersion = nil;
NSString* _NRMAAgentApplicationBundleId = nil;

//use this to verify that we don't execute critical code
//in the "onbackground" process after we've come back to the foreground.
static BOOL didFireEnterForeground;

@interface NewRelicConnectInfo : NSObject
@property(nonatomic, strong) id dataToken;
@end

@implementation NewRelicConnectInfo
@synthesize dataToken = _dataToken;
@end

@interface NewRelicAgentInternal() {

    /* Where we store observed network requests before sending them to New Relic */
    NSMutableArray* _transactionDataList;
    double _appLastBackgrounded;
    NSTimeInterval _startTime_ms;
}

/*
 The token sent from the RPM service on connect that is used when sending data.
 */

@property(nonatomic, readonly, strong) id dataToken;
@property(atomic, strong) NSDate* appSessionStartDate;
@property(nonatomic, readonly) BOOL collectNetworkErrors;
@property(nonatomic, assign) BOOL captureNetworkStackTraces;
@property(nonatomic, strong) NRMAAppInstallMetricGenerator* appInstallMetricGenerator;
@property(nonatomic, strong) NRMAAppUpgradeMetricGenerator* appUpgradeMetricGenerator;
@property(assign) BOOL appWillTerminate;

- (void) applicationWillEnterForeground;

- (void) applicationWillEnterForeground:(UIApplication*)application;

- (void) applicationDidEnterBackground;

- (void) applicationDidEnterBackground:(UIApplication*)application;

- (BOOL) isDisabled;


@end


/* The agent singleton */
static NewRelicAgentInternal* _sharedInstance;

@implementation NewRelicAgentInternal


@synthesize enabled = _enabled;
@synthesize dataToken = _dataToken;
@synthesize collectNetworkErrors = _collectNetworkErrors;
@synthesize captureNetworkStackTraces = _captureNetworkStackTraces;

@synthesize lifetimeRequestCount = _lifetimeRequestCount;
@synthesize lifetimeErrorCount = _lifetimeErrorCount;


- (NSDate*) getAppSessionStartDate {
    return self.appSessionStartDate;
}

+ (NewRelicAgentInternal*) sharedInstance {
    return _sharedInstance;
}

- (void) dealloc {
    NSLog(@"NewRelicAgentInternal -dealloc");
}

- (id) initWithCollectorAddress:(NSString*)collectorAddressIn
            andApplicationToken:(NRMAAppToken*)token {

    return [self initWithCollectorAddress:collectorAddressIn
                    crashCollectorAddress:nil
                      andApplicationToken:token];
}

- (id) initWithCollectorAddress:(NSString*)collectorHost
          crashCollectorAddress:(NSString*)crashCollectorHost
            andApplicationToken:(NRMAAppToken*)token {

    self = [super init];
    if (self) {
        self.appWillTerminate = NO;
        [NRMACPUVitals setAppStartCPUTime];
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
            didFireEnterForeground = YES;
        }
        self->_agentConfiguration = [[NRMAAgentConfiguration alloc] initWithAppToken:token
                                                                    collectorAddress:collectorHost
                                                                        crashAddress:crashCollectorHost];
        self->_captureNetworkStackTraces = NO;
        //NRMAAppInstallMetricGenerator and NRMAAppUpgradeMetricGenerator must be initialized ASAP to properly capture the
        //generation of the UDID & version change
        self.appInstallMetricGenerator = [NRMAAppInstallMetricGenerator new];
        self.appUpgradeMetricGenerator = [NRMAAppUpgradeMetricGenerator new];

        self->_lifetimeRequestCount = 0;
        self->_lifetimeErrorCount = 0;
        self.appSessionStartDate = [NSDate date];

        self->_enabled = ![self isDisabled];

        if (self->_enabled) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(applicationDidEnterBackground:)
                                                         name:UIApplicationDidEnterBackgroundNotification
                                                       object:[UIApplication sharedApplication]];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(applicationWillEnterForeground:)
                                                         name:UIApplicationWillEnterForegroundNotification
                                                       object:[UIApplication sharedApplication]];

            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(applicationWillTerminate)
                                                         name:UIApplicationWillTerminateNotification
                                                       object:[UIApplication sharedApplication]];

            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(didReceiveInteractionCompleteNotification:)
                                                         name:kNRInteractionDidCompleteNotification
                                                       object:nil];

            NRLOG_INFO(@"Agent enabled");


            /**** Store Data For Crash Reporter ****/

            if ([NRMAFlags shouldEnableCrashReporting]) {
                [NRMAExceptionDataCollectionWrapper startCrashMetaDataMonitors];
                _startTime_ms = NRMAMillisecondTimestamp();
                NRMA_setSessionStartTime([NSString stringWithFormat:@"%lld",
                                          (long long)_startTime_ms].UTF8String);
                NRMA_setAppToken([self->_agentConfiguration.applicationToken.value UTF8String]);
                NRMA_setAppVersion([NRMAAgentConfiguration connectionInformation].applicationInformation.appVersion.UTF8String);
                NSString* appBuild = [NRMAAgentConfiguration connectionInformation].applicationInformation.appBuild;
                if (appBuild.length) {
                    NRMA_setBuild(appBuild.UTF8String);
                }
                NRMA_setAppName([NRMAAgentConfiguration connectionInformation].applicationInformation.appName.UTF8String);
                NRMA_setTempDir(NSTemporaryDirectory().UTF8String);
            }
            [self initialize];
            [self onSessionStart];

            if ([NRMAFlags shouldEnableCrashReporting]) {
                NRMACrashReporterRecorder* crashReportRecorder = [[NRMACrashReporterRecorder alloc] init];
                [NRMAHarvestController addHarvestListener:crashReportRecorder];
            }

            //appInstallMetricGenerator will receive the 'new install' notification
            //before the harvester is setup and before the task queue is set up.
            //by adding the appInstallMetricGenerator to the harvestAwareListener
            //it will be signaled when the harvester is definitively available.
            [NRMAHarvestController addHarvestListener:self.appInstallMetricGenerator];
            [NRMAHarvestController addHarvestListener:self.appUpgradeMetricGenerator];
        } else {
            NRLOG_INFO(@"Agent disabled");
        }
    }
    return self;
}

- (void) didReceiveInteractionCompleteNotification:(NSNotification*)notif {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() {
        //this prevents a race condition between the the asynchonous behavior or the interaction events
        //and the termination of the application.
        @synchronized(kNRMA_BGFG_MUTEX) {
            @synchronized(kNRMA_APPLICATION_WILL_TERMINATE) {
                if (self.appWillTerminate) {
                    return;
                }
            }
            NRMAActivityTrace* trace = notif.object;
            [self.analyticsController addInteractionEvent:trace.name
                                      interactionDuration:trace.endTime - trace.startTime];
        }
    });
}

- (BOOL) isDisabled {
    return [[NRMAHarvestController harvestController] harvester].currentState == NRMA_HARVEST_DISABLED;
}


- (void) destroyAgent {
    //destroy?
    [NRMAHarvestController stop];
    //meh close enough
}

- (void) initialize {


    // update old files (no more files in the docs folder)
    [NRMAFileCleanup updateDocFileLocations];
    
    NRMAExceptionHandlerStartupManager* exceptionHandlerStartupManager = [[NRMAExceptionHandlerStartupManager alloc] init];

    //last session's analytics must be fetched (asynchronously) before instrumentation

    [exceptionHandlerStartupManager fetchLastSessionsAnalytics];

    [self initializeInstrumentation];

    if ([NRMAFlags shouldEnableInteractionTracing]) {
        [[NRMAMethodProfiler sharedInstance] startMethodReplacement];
    }

    if ([NRMAFlags shouldEnableCrashReporting]) {
        [exceptionHandlerStartupManager startExceptionHandler:[[NRMACrashDataUploader alloc] initWithCrashCollectorURL:_agentConfiguration.crashCollectorHost
                                                                                                      applicationToken:_agentConfiguration.applicationToken.value
                                                                                                 connectionInformation:[NRMAAgentConfiguration connectionInformation]
                                                                                                                useSSL:self->_agentConfiguration.useSSL]];
    }

    [NRMAHarvestController initialize:self->_agentConfiguration];
    /*
     * NRMAMeasurements must be started before the
     * harvest controller Or else there is a chance the
     * first data post will not have expected system
     * metrics: CPU/System/Utilization,
     * CPU/User/Utilization, CPU/Total/Utilization, and
     * Memory/Used.
     *
     * these metrics are generated in the
     * -onHarvestBefore method, which won't get called if
     * the measurements engine is initialized before the
     * harvestController, but if the measurements are
     * started too late, they will miss the first
     * -onHarvestBefore call of the harvester, and not
     * get posted.
     *
     * Session/Start will not get posted if the
     * measurements engine isn't initialized earlier
     * enough, but doesn't rely on -onHarvestBefore, so
     * it will still be posted if the measurements engine
     * is initialized too early.
     *
     * this is the goldilocks location for the
     * measurements engine initialization, before
     * harvester start, but after harvester
     * initialization.
     */
    [NRMAMeasurements initializeMeasurements];
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        [NRMAHarvestController start];
    }
}

/*
 Initialize all of the categories which swizzle into existing classes.
 */
- (void) initializeInstrumentation {
    static dispatch_once_t onceToken = 0;
    if (_NRMAAgentTestModeEnabled) {
        onceToken = 0;
    }
    dispatch_once(&onceToken,
                  ^{
                      [NewRelicAgentInternal instrumentWebViews];

                      if ([NRMAFlags shouldEnableNSURLSessionInstrumentation]) {
                          [NRMAURLSessionOverride beginInstrumentation];
                      }

                      if ([NRMAFlags shouldEnableGestureInstrumentation]) {
                          [self initializeGestureInstrumentation];
                      }

                      // Instrument NRNSURLConnection if not in 'experimental mode'
                      if (![NRMAFlags shouldEnableExperimentalNetworkingInstrumentation]) {
                          [NRMANSURLConnectionSupport instrumentNSURLConnection];
                      }
                  });
}


+ (void) instrumentWebViews {
    if ([NRMAFlags shouldEnableWebViewInstrumentation]) {
        [NRMAWKWebViewInstrumentation instrument];
    }
}

- (void) initializeGestureInstrumentation {
    if (![NRMAApplicationInstrumentation instrumentUIApplication]) {
        NRLOG_VERBOSE(@"Failed to instrument UIApplication -sendAction:...");
    }

    if (![NRMATableViewIntrumentation instrument]) {
        NRLOG_VERBOSE(@"failed to instrument UITableView.");
    }

    if (![NRMACollectionViewInstrumentation instrument]) {
        NRLOG_VERBOSE(@"Failed to instrument UICollectionView.");
    }

    //recognizer instrumentation needs more discussion. We want this disabled by default for now.
    if (![NRMAGestureRecognizerInstrumentation instrumentUIGestureRecognizer]) {
        NRLOG_VERBOSE(@"Failed to instrument gesture recognizer.");
    }
}


/*
 De-initialize agent instrumentation
 */
- (void) deinitializeInstrumentation {
    // unwind that which we have wrought
    [NRMAWKWebViewInstrumentation deinstrument];
}

- (double) appBackgroundedTimeInMillis {
    return NanosToMillis(NRMA_NanosecondsFromTimeInterval(self->_appLastBackgrounded));
}


/*
 The lock that should always be used when accessing the transaction data list.
 */
- (id) dataLock {
    return self;
}

- (void) carrierNameNotificationDidUpdate:(NSNotification*)notification {
    [self.analyticsController setNRSessionAttribute:@"carrier"
                                              value:notification.object];
}

- (void) memoryUsageDidUpdate:(NSNotification*)notification {
    [self.analyticsController setNRSessionAttribute:@"memUsageMb"
                                              value:notification.object];
}


static NSString* kNRMAAnalyticsInitializationLock = @"AnalyticsInitializationLock";

- (void) initializeAnalytics {
    @synchronized(kNRMAAnalyticsInitializationLock) {
        [NRMAAnalytics clearDuplicationStores];
        self.analyticsController = [[NRMAAnalytics alloc] initWithSessionStartTimeMS:(long long)([self.appSessionStartDate timeIntervalSince1970] * 1000)];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:kNRMAAnalyticsInitializedNotification
                                                        object:nil
                                                      userInfo:@{kNRMAAnalyticsControllerKey:self.analyticsController}];
    //    **uuid** (unique device install id)
    //    **osName **(ex. 'iOS' or 'Android')
    //    **osVersion  **(The entire OS version string, ex 4.1.2)
    //    **osMajorVersion **(The OS major version, in the above case this is 4.  Formatted as a string.)
    //    **deviceManufacturer **(ex. 'Apple', 'Samsung')
    //    **deviceModel** (ex. 'iPhone5,2', 'SMT-5400i')
    //    **carrier **(ex. 'Cingular')
    //    **newRelicVersion** (agent version #, ex. '3.512.1')
    //    **memUsageMb **(numeric memory usage in megabytes)
    //    **sessionId** (unique guid generated per session)

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(carrierNameNotificationDidUpdate:)
                                                 name:kNRCarrierNameDidUpdateNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(memoryUsageDidUpdate:)
                                                 name:kNRMemoryUsageDidChangeNotification
                                               object:nil];

    [self.analyticsController setNRSessionAttribute:@"uuid"
                                              value:[NewRelicInternalUtils deviceId]];


    [self.analyticsController setNRSessionAttribute:@"osName"
                                              value:[NewRelicInternalUtils osName]];


    NSString* systemVersion = [[UIDevice currentDevice] systemVersion];
    NSArray* versionComponents = [systemVersion componentsSeparatedByString:@"."];
    NSString* majorVersion = @"unknown";
    if (versionComponents.count > 0) {
        majorVersion = versionComponents[0];
    }
    if (systemVersion.length <= 0) {
        systemVersion = @"unknown";
    }

    [self.analyticsController setNRSessionAttribute:@"osMajorVersion"
                                              value:majorVersion];

    [self.analyticsController setNRSessionAttribute:@"osVersion"
                                              value:systemVersion];

    [self.analyticsController setNRSessionAttribute:@"deviceManufacturer"
                                              value:@"Apple Inc."];

    [self.analyticsController setNRSessionAttribute:@"deviceModel"
                                              value:[NewRelicInternalUtils deviceModel]];


    [self.analyticsController setNRSessionAttribute:@"newRelicVersion"
                                              value:[NewRelicInternalUtils agentVersion]];

    [self.analyticsController setNRSessionAttribute:@"appBuild"
                                              value:[NRMAAgentConfiguration connectionInformation].applicationInformation.appBuild];

    [self.analyticsController setNRSessionAttribute:@(__kNRMA_RA_platform)
                                              value:[NewRelicInternalUtils stringFromNRMAApplicationPlatform:[NRMAAgentConfiguration connectionInformation].deviceInformation.platform]];

    [self.analyticsController setNRSessionAttribute:@(__kNRMA_RA_platformVersion)
                                              value:[NRMAAgentConfiguration connectionInformation].deviceInformation.platformVersion];


    NSString* vendorId = [UIDevice currentDevice].identifierForVendor.UUIDString;
    if (vendorId.length && ![NRMAFlags shouldSaltDeviceUUID]) {
        //allows us to compare with udid.
        // don't record the vendor Id if the device id is salted.
        [self.analyticsController setNRSessionAttribute:kNRMAVendorIDAttribute
                                                  value:vendorId];
    }


    [NRMAHarvestController addHarvestListener:self.analyticsController];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        //this will trigger the the kNRCarrierNameDidUpdateNotification
        [NewRelicInternalUtils carrierName];
    });
}

- (NSString*) currentSessionId {
    return [self agentConfiguration].sessionIdentifier;
}

- (void) onSessionStart {
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString* uuid_String = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault,
                                                                            uuid);
    self->_agentConfiguration.sessionIdentifier = uuid_String;

    CFRelease(uuid);
    if (self->_agentConfiguration.sessionIdentifier.length > 0) {
        NRMA_setSessionId([self->_agentConfiguration.sessionIdentifier UTF8String]);
    }

    NRMA_setSessionStartTime([NSString stringWithFormat:@"%lld",
                              (long long)NRMAMillisecondTimestamp()].UTF8String);

    //initializing analytics take a while
    //BEWARE executing time sensitive code after this point
    // the initializeAnalytics method will delay its execution.
    [self initializeAnalytics];

    if ([NRMAFlags shouldEnableHandledExceptionEvents]) {
        self.handledExceptionsController = [[NRMAHandledExceptions alloc] initWithAnalyticsController:self.analyticsController
                                                                                     sessionStartTime:self.appSessionStartDate
                                                                                   agentConfiguration:self.agentConfiguration
                                                                                             platform:[NewRelicInternalUtils osName]
                                                                                            sessionId:[self currentSessionId]];

        [self.handledExceptionsController processAndPublishPersistedReports];

        [NRMAHarvestController addHarvestListener:self.handledExceptionsController];

    }
    [self.analyticsController setNRSessionAttribute:@"sessionId"
                                              value:self->_agentConfiguration.sessionIdentifier];

    //attempt to upload files (if any exist)
    if ([NRMAFlags shouldEnableCrashReporting]) {
	
        [[NRMAExceptionHandlerManager manager].uploader uploadCrashReports];
    }
    
    if([NRMAFlags shouldEnableGestureInstrumentation])
    {
        self.gestureFacade = [[NRMAUserActionFacade alloc] initWithAnalyticsController:self.analyticsController];

        NRMAUserAction* foregroundGesture = [NRMAUserActionBuilder buildWithBlock:^(NRMAUserActionBuilder *builder) {
            [builder withActionType:kNRMAUserActionAppLaunch];
        }];
        [self.gestureFacade recordUserAction:foregroundGesture];
    }

}

static const NSString* kNRMA_BGFG_MUTEX = @"com.newrelic.bgfg.mutex";
static const NSString* kNRMA_APPLICATION_WILL_TERMINATE = @"com.newrelic.appWillTerm";

- (void) applicationWillEnterForeground {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,
                                             0),
                   ^{
                       @synchronized(kNRMA_BGFG_MUTEX) {
                           @synchronized(kNRMA_APPLICATION_WILL_TERMINATE) {

                               if (didFireEnterForeground == YES || self.appWillTerminate == YES) {
                                   //why is this being fired more than once!?
                                   return;
                               }
                               didFireEnterForeground = YES;
                               self.appSessionStartDate = [NSDate date];
                               [NRMACPUVitals setAppStartCPUTime];

                               [NRMAMeasurements shutdown];
                               [NRMAHarvestController stop];

                               [NRMAHarvestController initialize:self->_agentConfiguration];

                               /*
                                * NRMAMeasurements must be started before the
                                * harvest controller Or else there is a chance the
                                * first data post will not have expected system
                                * metrics: CPU/System/Utilization,
                                * CPU/User/Utilization, CPU/Total/Utilization, and
                                * Memory/Used.
                                *
                                * these metrics are generated in the
                                * -onHarvestBefore method, which won't get called if
                                * the measurements engine is initialized before the
                                * harvestController, but if the measurements are
                                * started too late, they will miss the first
                                * -onHarvestBefore call of the harvester, and not
                                * get posted.
                                *
                                * Session/Start will not get posted if the
                                * measurements engine isn't initialized earlier
                                * enough, but doesn't rely on -onHarvestBefore, so
                                * it will still be posted if the measurements engine
                                * is initialized too early.
                                *
                                * this is the goldilocks location for the
                                * measurements engine initialization, before
                                * harvester start, but after harvester
                                * initialization.
                                */
                               [NRMAMeasurements initializeMeasurements];
                               [NRMAHarvestController start];
                               [self onSessionStart];
                           }
                       }
                   });


}


- (void) applicationWillEnterForeground:(UIApplication*)application {
    [self applicationWillEnterForeground];
}

/*
 Queues a background task to send data to the New Relic service if anything is pending.
 */


static UIBackgroundTaskIdentifier background_task;

- (void) applicationWillTerminate {
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @synchronized(kNRMA_APPLICATION_WILL_TERMINATE) {
            self.appWillTerminate = YES;

            [self agentShutdown];

            if (background_task != UIBackgroundTaskInvalid) {
                [[UIApplication sharedApplication] endBackgroundTask:background_task]; // end the task
                background_task = UIBackgroundTaskInvalid; // invalidate the background_task
            }
        }
    });

}

- (void) applicationDidEnterBackground {
    if (didFireEnterForeground != YES) {
        //wat? apparently this can happen.
        NRLOG_VERBOSE(@"applicationDidEnterBackground called before didEnterForeground called.");
        return;
    }

    didFireEnterForeground = NO; //we are leaving the background

    [[NRMAHarvestController harvestController].harvestTimer stop];

    //disable observers

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kNRCarrierNameDidUpdateNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kNRMemoryUsageDidChangeNotification
                                                  object:nil];

    NRLOG_INFO(@"applicationDidEnterBackground");
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
    @try {
#endif
        [NRMATraceController completeActivityTrace];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
        [NRMAInteractionHistoryObjCInterface deallocInteractionHistory];
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                     class:NSStringFromClass([self class])
                                  selector:NSStringFromSelector(_cmd)];
    }
#endif
    // record the time at which the app goes to the background
    self->_appLastBackgrounded = mach_absolute_time();
    // check if the iOS version supports multitasking
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] &&
        [[UIDevice currentDevice] isMultitaskingSupported]) {


        UIApplication* application = [UIApplication sharedApplication];

        // mark the start of our background task
        background_task = [application beginBackgroundTaskWithExpirationHandler:^{
            // this handler fires when our remaining background time approaches 0.  We should not get here normally
            [application endBackgroundTask:background_task];
            background_task = UIBackgroundTaskInvalid;
        }];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,
                                                 0),
                       ^{
                           @synchronized(kNRMA_BGFG_MUTEX) {
                               if (didFireEnterForeground == YES) {
                                   //we set this to when we entered the background,
                                   //if this is yes, then we have entered the foreground
                                   //before this stuff could fire, so let's cancel doing this garbage.
                                   NRLOG_VERBOSE(@"entered foreground before background could complete, bailing out of background logging.");
                                   return;
                               }
                               @synchronized(kNRMA_APPLICATION_WILL_TERMINATE) {
                                   if (self.appWillTerminate) {
                                       return;
                                   }
                                   NSTimeInterval sessionLength = [[NSDate date] timeIntervalSinceDate:self.appSessionStartDate];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
                                   @try {
#endif
                                       self.gestureFacade = nil;
                                       [self.analyticsController sessionWillEnd];
                                       [NRMATaskQueue queue:[[NRMAMetric alloc]        initWithName:@"Session/Duration"
                                                                                              value:[NSNumber numberWithDouble:sessionLength]
                                                                                              scope:nil]];


#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
                                   } @catch (NSException* exception) {
                                       [NRMAExceptionHandler        logException:exception
                                                                           class:NSStringFromClass([self class])
                                                                        selector:NSStringFromSelector(_cmd)];
                                   }
#endif
                               } // end synchronized
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
                               @try {
#endif
                                   if (self.appWillTerminate) {
                                       return;
                                   }
                                   NRLOG_VERBOSE(@"Harvesting data in background");
                                   [[[NRMAHarvestController harvestController] harvester] execute];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
                               } @catch (NSException* exception) {
                                   [NRMAExceptionHandler        logException:exception
                                                                       class:NSStringFromClass([NRMAHarvester class])
                                                                    selector:@"execute"];
                               } @finally {
                                   [self agentShutdown];
                               }
#endif

                               NRLOG_VERBOSE(@"Background harvest complete.");

                               [application endBackgroundTask:background_task]; // end the task
                               background_task = UIBackgroundTaskInvalid; // invalidate the background_task
                           }
                       });
    } else {
        // we shouldn't ever get here because the minimum iOS version supported by the agent supports multitasking

        // FIXME do we hit this code path if UIApplicationExitsOnSuspend flag is set in Info.plist?
        //  ("Application does not run in background" in XCode)
        // if so we should document that the agent will not report data when the user closes the app
        [NRMAHarvestController stop];
        NRLOG_ERROR(@"Multitasking is not supported.  Clearing data.");

    }
}

- (void) applicationDidEnterBackground:(UIApplication*)application {
    [self applicationDidEnterBackground];
}

- (void) agentShutdown {
    [NRMAMeasurements shutdown];

    [NRMAHarvestController removeHarvestListener:self.analyticsController];
    [NRMAHarvestController removeHarvestListener:self.appInstallMetricGenerator];
    [NRMAHarvestController removeHarvestListener:self.appUpgradeMetricGenerator];
    if ([NRMAFlags shouldEnableHandledExceptionEvents]) {
        [NRMAHarvestController removeHarvestListener:self.handledExceptionsController];
    }

    [NRMAHarvestController stop];

    self.handledExceptionsController = nil; // handled exceptions depends on analyticsController destruct first.

    @synchronized(kNRMAAnalyticsInitializationLock) {
        self.analyticsController = nil;
    }


    [NRMALastActivityTraceController clearLastActivityStamp];

}

+ (BOOL) harvestNow {
    return [NRMAHarvestController harvestNow];
}

+ (void) startWithApplicationToken:(NSString*)appToken
               andCollectorAddress:(NSString*)url {

    [self startWithApplicationToken:appToken
                andCollectorAddress:url
           andCrashCollectorAddress:nil];

}

+ (void) startWithApplicationToken:(NSString*)appToken
               andCollectorAddress:(NSString*)url
          andCrashCollectorAddress:(NSString*)crashCollector {
    if ([NRMANonARCMethods OSMajorVersion] < 5) {
        NRLOG_WARNING(@"NewRelic: Cowardly avoiding initialization on pre-iOS 5 device");
        return;
    }

    static dispatch_once_t onceToken = 0;
    if (_NRMAAgentTestModeEnabled) {
        onceToken = 0;
    }

    if (!appToken.length) {
        NRLOG_ERROR(@"appToken must not be nil. Agent start aborted.");
        return;
    }


    dispatch_once(&onceToken,
                  ^{
                      _sharedInstance = [[NewRelicAgentInternal alloc] initWithCollectorAddress:url
                                                                          crashCollectorAddress:crashCollector
                                                                            andApplicationToken:[[NRMAAppToken alloc] initWithApplicationToken:appToken]];

                      if (_sharedInstance.enabled) {
                          NRLOG_INFO(@"The New Relic Agent started");
                      } else {
                          NRLOG_INFO(@"The New Relic Agent is disabled");
                      }
                  });
}

#pragma mark - API Pass Through
//We don't want to include NewRelic.h into any internal code
//because NewRelic.h includes GCDOverride, which messes up our
//GCD stuff





#pragma mark - Feature Flag Handler


@end
