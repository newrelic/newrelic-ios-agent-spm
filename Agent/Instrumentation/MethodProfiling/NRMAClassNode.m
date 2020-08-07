//
//  NRMAClassNode.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/18/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAClassNode.h"

@implementation NRMAClassNode
- (instancetype) initWithName:(NSString*)name
{
    self = [super init];
    if (self){
        self.name = name;
        self.children = [[NSMutableSet alloc] init];
    }
    return self;
    
    
}
- (BOOL) isEqual:(id) object
{
    if (![object isKindOfClass:self.class]) {
        return NO;
    }
    
    NRMAClassNode * that = (NRMAClassNode *)object;
    
    return [self.name isEqualToString:that.name];
}

- (NSString*) description
{
    return self.name;
}

- (NSUInteger) hash //required for NSSet
{
    return [self.name hash];
}
@end
