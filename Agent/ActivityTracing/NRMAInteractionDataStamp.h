//
//  NRMAInteractionData.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 7/8/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NRMAInteractionDataStamp : NSObject <NSCopying>
@property(atomic,strong) NSString* name;
@property(atomic,strong) NSNumber* startTimestamp;
@property(atomic,strong) NSNumber* duration;

- (id) JSONObject;

@end
