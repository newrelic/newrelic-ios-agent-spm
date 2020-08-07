//
//  NRMAExceptionHandlerManager.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/17/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAHarvestController.h"

@class NRMACrashDataUploader;

@interface NRMAExceptionHandlerManager : NSObject <NRMAHarvestAware>
@property(strong) NRMACrashDataUploader* uploader;
+ (NRMAExceptionHandlerManager*) manager;

+ (void) startHandlerWithLastSessionsAttributes:(NSDictionary*)attributes
                             andAnalyticsEvents:(NSArray*)events
                                  uploadManager:(NRMACrashDataUploader*)uploader;
@end
