//
//  NRMAUncaughtExceptionHandler.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/15/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLCrashNamespace.h"
#import "PLCrashReporter.h"
@interface NRMAUncaughtExceptionHandler : NSObject
- (instancetype) initWithCrashReporter:(PLCrashReporter*)crashReporter;

- (BOOL) start;
- (BOOL) stop;

- (BOOL) isActive;
- (BOOL) isExceptionHandlerValid;
@end
