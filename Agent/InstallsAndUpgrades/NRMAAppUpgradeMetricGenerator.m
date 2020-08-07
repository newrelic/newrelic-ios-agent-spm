//
//  NRMAAppUpgradeMetricGenerator.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/19/15.
//  Copyright © 2015 New Relic. All rights reserved.
//

#import "NRMAAppUpgradeMetricGenerator.h"
#import "NRConstants.h"
#import "NRMATaskQueue.h"
#import "NRMAMetric.h"
#import "NRMAAnalytics.h"
#import "NRMABool.h"
#import <Analytics/Constants.hpp>

@interface NRMAAppUpgradeMetricGenerator ()
@property(strong) NRMAMetric* upgradeMetric;
@property(strong) NSString* lastVersion;
@property(assign) BOOL shouldGenerateUpgradeAttribute;
@property(assign) BOOL shouldGenerateDeviceDidChangeAttribute;
@property(weak) NRMAAnalytics* analyticsController;
@end

@implementation NRMAAppUpgradeMetricGenerator

- (instancetype) init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangeAppVersion:)
                                                     name:kNRMADidChangeAppVersionNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didInitializeAnalytics:)
                                                     name:kNRMAAnalyticsInitializedNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deviceDidChange:)
                                                     name:kNRMADeviceDidChangeNotification
                                                   object:nil];
    }
    self.shouldGenerateUpgradeAttribute = NO;
    self.shouldGenerateDeviceDidChangeAttribute = NO;

    return self;
}

- (void) removeAnalyticsObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kNRMAAnalyticsInitializedNotification
                                                  object:nil];
}

- (void) removeChangeAppVersionObserver{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kNRMADidChangeAppVersionNotification
                                                  object:nil];
}

- (void) removeDeviceDidChangeObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kNRMADeviceDidChangeNotification
                                                  object:self];
}

- (void) dealloc {
    [self removeChangeAppVersionObserver];
    [self removeAnalyticsObserver];
    [self removeDeviceDidChangeObserver];
    self.analyticsController = nil;
}


- (void) sendDeviceChangedToAnalytics:(NRMAAnalytics* )analyticsController {
    [analyticsController setNRSessionAttribute:kNRMADeviceChangedAttribute
                                         value:[[NRMABool alloc] initWithBOOL:YES]];
}

- (void) deviceDidChange:(NSNotification*)notif {
    @synchronized(self) {
        [self removeDeviceDidChangeObserver];
        if(self.analyticsController) {
            [self sendDeviceChangedToAnalytics:self.analyticsController];
        } else {
         self.shouldGenerateDeviceDidChangeAttribute = YES;
        }
    }
}

- (void) didChangeAppVersion:(NSNotification*)notif {
    //notif contains UDID in user dictionary
    @synchronized(self) {
        //this notification should only fire 0 or 1 time per app lifecycle, but why risk it?
        [self removeChangeAppVersionObserver];
        self.lastVersion = notif.userInfo[kNRMALastVersionKey];
        //At the point in time this notification is fired, the measurements engine
        //(and the harvester, for that matter) is not yet initialized. The metric will be stored,
        //and it will be defered to NewRelicAgentInternal.m to queue this object
        //as a harvest listener. Once the harvest listener is fired this metric will be queue
        //from -onHarvestBefore.
        self.upgradeMetric = [[NRMAMetric alloc] initWithName:kNRMAAppUpgradeMetric
                                                        value:@1
                                                        scope:nil];

        if(self.analyticsController) {
            //this code path is unlikely to ever occur. The analytics engine will
            //most likely never be initialized at the time of this execution.
            [self sendAppUpgradeToAnalytics:self.analyticsController];

            //Once the session attribute is recorded the analytics controller is
            //no longer needed for this application lifecycle.
            self.analyticsController = nil;
        } else {
            //If kNRMADidChangeAppVersionNotification is fired this code path will most likely
            //be executed. There should be no situation that kNRMAAnalyticsInitializedNotification
            //is observed before this notification.
            //To effectively record a session attribute identifying a new install occured,
            //we must wait for the analytics controller to be initialized. This flag will inidicate
            //we received the kNRMAAnalyticsInitializedNotification notification when the analytics
            //controller is available  to receive input.
            self.shouldGenerateUpgradeAttribute = YES;
        }

    }
}

- (void) sendAppUpgradeToAnalytics:(NRMAAnalytics*)analyticsController {
    [analyticsController setNRSessionAttribute:@(__kNRMA_RA_upgradeFrom) value:self.lastVersion];
}

- (void) onHarvestBefore {
    //TODO: this only needs to be called once... it could be considered to remove this
    //harvest listener once it queues the metric. This will only be called once
    //per install, and doesn't need to hang around.
    @synchronized(self) {
        if (self.upgradeMetric) {
            [NRMATaskQueue queue:self.upgradeMetric];
            self.upgradeMetric = nil;
        }
    }
}

- (void) didInitializeAnalytics:(NSNotification*)notif {

    //can this ever get called before -didChangeAppVersion: ? (probably not, but you never know.)

    //synchronized to ensure these operations are atomic in regards to the didChangeAppVersion
    //notification.
    @synchronized(self) {
        //this notification should only fire once per session, but why risk it?
        [self removeAnalyticsObserver];
        
        //a reference to the AnalyticsController is provided by the notification
        NRMAAnalytics* analytics = notif.userInfo[kNRMAAnalyticsControllerKey];
        
        if (self.shouldGenerateUpgradeAttribute) {
            //if kNRMAAnalyticsInitializedNotification was already captured,
            //immediately generate the new attribute using the analytics controller ref.
            [self sendAppUpgradeToAnalytics:analytics];
        }

        if (self.shouldGenerateDeviceDidChangeAttribute) {
            [self sendDeviceChangedToAnalytics:analytics];
        }

        //kNRMAAnalyticsInitializedNotification hasn't been captured yet (or may never be captured)
        //Hold onto the ref to the analyticsController in a weak property in case we see the notification later
        //if kNRMAAnalyticsInitializedNotification will be generated for this app install this code path will not
        //execute. However, this path will execute for most app sessions when there is already a valid UDID.
        //There should be no issue with holding onto this weak reference, as the property will be niled out when
        //the ref is deallocated.
        self.analyticsController = analytics;
    }
}
@end
