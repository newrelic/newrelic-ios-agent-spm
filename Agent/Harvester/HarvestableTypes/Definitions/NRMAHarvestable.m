//
//  NRMAHarvestable.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/26/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestable.h"

@implementation NRMAHarvestable

- (id) initWithType:(NRMAHarvestableType)type
{
    self = [super init];
    if (self) {
        _type = type;
    }
    return self;
}

- (id) JSONObject
{
    return nil;
}

- (void) notEmpty:(NSString*)argument
{
    if (!argument.length) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Missing Harvestable Field."
                                     userInfo:nil];
    }
}
- (void) notNull:(id)argument
{
    if (argument == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Nil field in Harvestable object"
                                     userInfo:nil];
    }
}
- (NSString*) optional:(NSString*)argument
{
   if (argument == nil)
       return @"";
    return argument;
}
@end
