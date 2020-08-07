//
//  NRMANamedValueMeasurement.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/30/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMeasurement.h"

#ifdef __cplusplus
 extern "C" {
#endif

@interface NRMANamedValueMeasurement : NRMAMeasurement
@property(strong, nonatomic) NSNumber* value;
@property(strong, nonatomic) NSString* scope;

- (instancetype) initWithName:(NSString*)name
                        value:(NSNumber*)value;
@end

#ifdef __cplusplus
}
#endif
