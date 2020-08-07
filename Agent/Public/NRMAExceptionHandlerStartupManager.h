//
//  NRMAExceptionHandlerStartupManager.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/5/17.
//  Copyright © 2017 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NRMACrashDataUploader;

@interface NRMAExceptionHandlerStartupManager : NSObject

@property(strong) NSString* eventJson;
@property(strong) NSString* attributeJson;

- (void) fetchLastSessionsAnalytics;

- (void) startExceptionHandler:(NRMACrashDataUploader*)uploader;
@end
