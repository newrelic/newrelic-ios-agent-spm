//
//  Copyright © 2018 New Relic. All rights reserved.
//

#import "NRMAAnalytics.h"
#import <Connectivity/Payload.hpp>
#import <Analytics/AnalyticsController.hpp>

#ifndef NRMAAnalyticsController_CppInterface_h
#define NRMAAnalyticsController_CppInterface_h

@interface NRMAAnalytics (cppInterface)
- (std::shared_ptr<NewRelic::AnalyticsController>&) analyticsController;

- (BOOL)addGestureEvent:(NSString *)functionExecuted
           targetObject:(NSString *)targetObject
                  label:(NSString *)label
          accessibility:(NSString *)accessibility
         tapCoordinates:(NSString *)tapCoordinates
            gestureType:(NSString *)gestureType
           controlFrame:(NSString *)controlFrame
                payload:(std::unique_ptr<const NewRelic::Connectivity::Payload>)payload;

- (BOOL) addNetworkRequestEvent:(NRMANetworkRequestData*)requestData
                   withResponse:(NRMANetworkResponseData*)responseData
                    withPayload:(std::unique_ptr<const NewRelic::Connectivity::Payload>)payload;

- (BOOL) addNetworkErrorEvent:(NRMANetworkRequestData *)requestData
                 withResponse:(NRMANetworkResponseData *)responseData
                  withPayload:(std::unique_ptr<const NewRelic::Connectivity::Payload>)payload;

- (BOOL) addHTTPErrorEvent:(NRMANetworkRequestData *)requestData
              withResponse:(NRMANetworkResponseData *)responseData
               withPayload:(std::unique_ptr<const NewRelic::Connectivity::Payload>)payload;
@end


#endif /* NRMAAnalyticsController_CppInterface_h */
