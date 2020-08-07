//
//  NRMADataToken.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/4/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMADataToken.h"

@implementation NRMADataToken
- (id) JSONObject
{
    NSMutableArray* jsonArray = [[NSMutableArray alloc] initWithCapacity:2];
    [jsonArray addObject:[NSNumber numberWithLongLong:self.clusterAgentId]];
    [jsonArray addObject:[NSNumber numberWithLongLong:self.realAgentId]];
    return jsonArray;
}

- (BOOL) isValid
{
    return self.clusterAgentId > 0 && self.realAgentId > 0;
}

- (NSUInteger) hash {
    return (NSUInteger)(self.clusterAgentId | self.realAgentId);
}

- (BOOL) isEqual:(id)object
{
    if (![object isKindOfClass:[NRMADataToken class]]) {
        return NO;
    }
    NRMADataToken* token = (NRMADataToken*)object;
    
    if (self == object)return YES;
    
    if (self.clusterAgentId != token.clusterAgentId) {
        return NO;
    }
    
    return self.realAgentId == token.realAgentId;
    
}
@end
