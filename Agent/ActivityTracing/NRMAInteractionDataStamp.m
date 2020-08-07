//
//  NRMAInteractionData.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 7/8/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAInteractionDataStamp.h"

@implementation NRMAInteractionDataStamp

- (id) copyWithZone:(NSZone*)zone
{
    NRMAInteractionDataStamp* copy = [[NRMAInteractionDataStamp alloc] init];
    copy.name = self.name;
    copy.startTimestamp = self.startTimestamp;
    copy.duration = self.duration;
    return copy; 
}



- (NSUInteger) hash
{
    return [self.name hash] | [self.startTimestamp hash] | [self.duration hash];
}

- (BOOL) isEqual:(id)object
{
    if(![object isKindOfClass:[self class]]) {
        return NO;
    }

    NRMAInteractionDataStamp* typedObj = (NRMAInteractionDataStamp*)object;

    if (![self.name isEqualToString:typedObj.name]) {
        return NO;
    }

    if (![self.duration isEqual:typedObj.duration]) {
        return NO;
    }

    if (![self.startTimestamp isEqual:typedObj.startTimestamp]) {
        return NO;
    }

    return YES;
}

- (id) JSONObject
{
    if (self.name == nil
        || self.startTimestamp == nil
        || self.duration == nil) {
        return @[];
    }

    NSMutableArray* array = [[NSMutableArray alloc] init];
    [array addObject:@{@"type":@"ACTIVITY_HISTORY"}];
    [array addObject:self.name];
    [array addObject:self.startTimestamp];
    [array  addObject:self.duration];

    return array;
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"\n{\n\tname: %@\n\tduration: %@\n\tstartTimestamp: %@\n}\n",self.name,self.duration,self.startTimestamp];
}

@end
