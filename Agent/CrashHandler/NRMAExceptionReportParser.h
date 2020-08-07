//
//  NRExceptionReportParser.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/21/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLCrashNamespace.h"
#import "PLCrashReport.h"
@interface NRMAExceptionReportParser : NSObject
+ (id) JSONObjectFromPLCrashReport:(PLCrashReport*)report;
@end
