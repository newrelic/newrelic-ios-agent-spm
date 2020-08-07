//
// Created by Bryce Buchanan on 2/9/15.
// Copyright (c) 2015 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NRMAHarvestableArray.h"

@interface NRMAHarvestableAnalytics : NRMAHarvestableArray
{
    NSDictionary* _sessionAttributes;
    NSArray* _events;
}
@property (strong) NSDictionary* sessionAttributes;
@property (strong) NSArray* events;
- (id) initWithAttributeJSON:(NSString*)attributeJSON EventJSON:(NSString*)eventJSON;
- (id) JSONObject;
@end
