//
//  NRMeasurementException.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/20/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMeasurementException.h"
#ifdef __cplusplus
extern "C" {
#endif


@implementation NRMAMeasurementException
- (id) initWithName:(NSString *)aName
             reason:(NSString *)aReason
           userInfo:(NSDictionary *)aUserInfo
{
    return [super initWithName:aName
                        reason:aReason
                      userInfo:aUserInfo];
}
@end

#ifdef __cplusplus
}
#endif
