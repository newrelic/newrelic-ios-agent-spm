//
//  NRMALastActivityTraceController.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 7/8/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAInteractionDataStamp.h"

@interface NRMALastActivityTraceController : NSObject

+ (void) storeLastActivityStampWithName:(NSString*)name
                         startTimestamp:(NSNumber*)timestampMillis
                               duration:(NSNumber*)durationMillis;

+ (void) clearLastActivityStamp;

+ (NRMAInteractionDataStamp*) copyLastActivityStamp;
@end
