//
//  NRMAUncaughtExceptionHandler.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/15/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAUncaughtExceptionHandler.h"
#import "NRLogger.h"
#import <sys/sysctl.h>

@interface NRMAUncaughtExceptionHandler ()
@property(strong) PLCrashReporter* crashReporter;
@property(assign,getter = isAppStoreEnvironment) BOOL appStoreEnvironmentEnabled;
@property(assign) NSUncaughtExceptionHandler* exceptionHandler;
@property(assign,atomic) BOOL isStarted;
@end
@implementation NRMAUncaughtExceptionHandler


- (instancetype) initWithCrashReporter:(PLCrashReporter*)crashReporter
{
    self = [super init];
    if (self) {
        _isStarted = NO;
        _crashReporter = crashReporter;
        _appStoreEnvironmentEnabled = NO;
        #if  !TARGET_IPHONE_SIMULATOR
        if (![[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"]) {
            _appStoreEnvironmentEnabled = YES;
        }
        #endif //!TARGET_IPHONE_SIMULATOR
    }
    return self;
}

- (BOOL) isActive
{
    return _isStarted;
}
- (BOOL)isDebuggerAttached {
    static BOOL debuggerIsAttached = NO;

    static dispatch_once_t debuggerPredicate;
    dispatch_once(&debuggerPredicate, ^{
        struct kinfo_proc info;
        size_t info_size = sizeof(info);
        int name[4];

        name[0] = CTL_KERN;
        name[1] = KERN_PROC;
        name[2] = KERN_PROC_PID;
        name[3] = getpid();

        if (sysctl(name, 4, &info, &info_size, NULL, 0) == -1) {
            NRLOG_VERBOSE(@"Checking for a running debugger via sysctl() failed: %s", strerror(errno));
            debuggerIsAttached = false;
        }

        if (!debuggerIsAttached && (info.kp_proc.p_flag & P_TRACED) != 0)
            debuggerIsAttached = true;
    });
    
    return debuggerIsAttached;
}


- (BOOL) start
{
    __block BOOL startSuccessful = NO;
    //validate we aren't already running
    if ([self isActive]) {
        NRLOG_ERROR(@"Attempted to set exception handler when it was already set.");
        return NO;
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        //verify no debugger is running
        //if we were to initialize the crash reporter anyway then we would replace
        //the debugger... and debugging stops working.
        BOOL isDebugging = NO;
        if (![self isAppStoreEnvironment]) {
            if ([self isDebuggerAttached]) {
                isDebugging = YES;
                NRLOG_ERROR(@"New Relic Crash Reporting is DISABLED because it has detected the debugger is enabled.");
            }
        }

        if (!isDebugging) {
            //fetch current exception handler
            NSUncaughtExceptionHandler* originalHandler = NSGetUncaughtExceptionHandler();

            NSError* error = nil;
            if (![_crashReporter enableCrashReporterAndReturnError:&error]) {
                NRLOG_ERROR(@"Could not start crash reporter: %@",[error localizedDescription]);
                startSuccessful =  NO;
                return;
            }

            NSUncaughtExceptionHandler* newHandler = NSGetUncaughtExceptionHandler();

            //verify the top level handler changed
            if (newHandler && newHandler != originalHandler) {
                _exceptionHandler = newHandler;
                self.isStarted = YES;
                NRLOG_INFO(@"Exception handler initialized.");
                startSuccessful = YES;
            } else {
                NRLOG_ERROR(@"Set exception handler failed. Verify no other exception handlers have been set!");
                startSuccessful = NO;
            }
        }
    });

    return startSuccessful;
}
- (BOOL) stop
{
    return NO;
}

- (BOOL) isExceptionHandlerValid
{
    NSUncaughtExceptionHandler* currentExceptionHandler = NSGetUncaughtExceptionHandler();
    return _exceptionHandler == currentExceptionHandler;
}
@end
