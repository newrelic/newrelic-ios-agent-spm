//
//  NRMACrashDataWriter.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/7/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLCrashNamespace.h"
#import "PLCrashReport.h"

@interface NRMACrashDataWriter : NSObject

+ (BOOL) writeCrashReport:(PLCrashReport*)report
             withMetaData:(NSDictionary*)metaDictionary
        sessionAttributes:(NSDictionary*)attributes
          analyticsEvents:(NSArray*)events;
@end
