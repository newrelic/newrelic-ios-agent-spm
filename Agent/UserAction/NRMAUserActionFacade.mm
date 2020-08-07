//
//  NRMAUserActionFacade.m
//

#import "NRMAUserActionFacade.h"
#import "NRMAAnalytics+cppInterface.h"
#include <Connectivity/Facade.hpp>
#import "NRLogger.h"
#import "NewRelicInternalUtils.h"

@interface NRMAUserActionFacade () {
    std::shared_ptr<NewRelic::AnalyticsController> wrappedAnalyticsController;
}
@end

@implementation NRMAUserActionFacade

- (instancetype)initWithAnalyticsController:(NRMAAnalytics *)analytics {
    self = [super init];
    if (self) {
        wrappedAnalyticsController = std::shared_ptr<NewRelic::AnalyticsController>([analytics analyticsController]);
    }
    return self;
}

- (void)recordUserAction:(NRMAUserAction *)userAction {
    try {
        wrappedAnalyticsController->addUserActionEvent(userAction.associatedMethod.UTF8String,
                userAction.associatedClass.UTF8String,
                userAction.elementLabel.UTF8String,
                userAction.accessibilityId.UTF8String,
                userAction.interactionCoordinates.UTF8String,
                userAction.actionType.UTF8String,
                userAction.elementFrame.UTF8String,
                [NewRelicInternalUtils deviceOrientation].UTF8String);
    } catch (std::exception &error) {
        NRLOG_VERBOSE(@"Failed to add TrackedGesture: %s.", error.what());
    } catch (...) {
        NRLOG_VERBOSE(@"Failed to add TrackedGesture: unknown error.");
    }
}

@end
