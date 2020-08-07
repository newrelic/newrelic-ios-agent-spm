//
//  NRMACrashReportsManager.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/17/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLCrashNamespace.h"
#import "PLCrashReporter.h"
@interface NRMACrashReportFileManager : NSObject
- (instancetype) initWithCrashReporter:(PLCrashReporter*)crashReporter;

- (void) processReportsWithSessionAttributes:(NSDictionary*)attributes
                             analyticsEvents:(NSArray*)events;
@end
