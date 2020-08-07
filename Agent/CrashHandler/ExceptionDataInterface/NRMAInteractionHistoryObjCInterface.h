//
//  NRMAInteractionHistoryObjCInterface.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/19/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NRMAInteractionHistoryObjCInterface : NSObject
+ (void) insertInteraction:(NSString*)name startTime:(long long)epochMillis;
+ (void) deallocInteractionHistory;
@end
