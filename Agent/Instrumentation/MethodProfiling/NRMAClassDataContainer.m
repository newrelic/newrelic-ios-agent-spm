//
//  NRMAClassDataContainer.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/15/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAClassDataContainer.h"

@implementation NRMAClassDataContainer

- (instancetype) initWithCls:(Class)cls className:(NSString*)name
{
    self = [super init];
    if (self) {

        _storedClass = cls;
        _name = name;
    }
    return self;
}
- (id)copyWithZone:(NSZone *)zone
{
    return [[NRMAClassDataContainer allocWithZone:zone] initWithCls:self.storedClass
                                                          className:self.name];
}

- (void) dealloc
{
    _storedClass = nil;
    _name = nil;
}
- (NSUInteger) hash {
    return [self.name hash];
}

- (BOOL) isEqual:(id)object
{
    if (![object isKindOfClass:self.class]) {
        return NO;
    }

    return ((NRMAClassDataContainer*)object).storedClass == self.storedClass;
}

@end
