//
//  New Relic for Mobile -- iOS edition
//
//  See:
//    https://docs.newrelic.com/docs/mobile-apps for information
//    https://docs.newrelic.com/docs/releases/ios for release notes
//
//  Copyright (c) 2013 New Relic. All rights reserved.
//  See https://docs.newrelic.com/docs/licenses/ios-agent-licenses for license details
//

#import <Foundation/Foundation.h>
#import "NRTimer.h"
#import "NRConstants.h"

extern NSString * const kNRTraceAssociatedKey;

NSString* NSStringFromNRMATraceType (enum NRTraceType category);

@interface NRMACustomTrace : NSObject
+ (void) startTracingMethod:(SEL)selector
                 objectName:(NSString*)objectName
                      timer:(NRTimer*)timer
                   category:(enum NRTraceType)category;

+ (void) endTracingMethodWithTimer:(NRTimer*)timer;
@end

