//
//  NRMAExceptionHandlerStartupManager.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/5/17.
//  Copyright © 2017 New Relic. All rights reserved.
//

#import "NRMAExceptionHandlerStartupManager.h"
#import "NRMAExceptionHandlerManager.h"
#import "NRMAAnalytics.h"
#import "NRMACrashDataUploader.h"

@implementation NRMAExceptionHandlerStartupManager

- (void) fetchLastSessionsAnalytics{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @synchronized (self) {
            self.attributeJson = [NRMAAnalytics getLastSessionsAttributes];

            self.eventJson = [NRMAAnalytics getLastSessionsEvents];
        }
    });
}

- (void) startExceptionHandler:(NRMACrashDataUploader*)uploader {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @synchronized (self) {

            NSError* serializationError;
            NSArray* events;
            NSDictionary* attributes;

            @try {
                events = [NSJSONSerialization JSONObjectWithData:[self.eventJson dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:0
                                                           error:&serializationError];
                if (serializationError != nil) {
                    NRLOG_VERBOSE(@"Failed to load last session's events for crash: %@",serializationError.localizedDescription);
                }
            } @catch (NSException* e) {
                NRLOG_VERBOSE(@"failed to serialize event json: %@",e.reason);
            }

            @try {
                attributes = [NSJSONSerialization JSONObjectWithData:[self.attributeJson dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:0
                                                               error:&serializationError];
                if (serializationError != nil) {
                    NRLOG_VERBOSE(@"Failed to load last session's attribute for crash: %@",serializationError.localizedDescription);
                }
            } @catch (NSException* e) {
                NRLOG_VERBOSE(@"failed to serialize event json: %@",e.reason);
            }

            [NRMAExceptionHandlerManager startHandlerWithLastSessionsAttributes:attributes
                                                             andAnalyticsEvents:events
                                                                  uploadManager:uploader];
        }
    });
}
@end
