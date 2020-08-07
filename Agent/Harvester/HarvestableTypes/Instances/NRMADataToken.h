//
//  NRMADataToken.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/4/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestableArray.h"
@interface NRMADataToken : NRMAHarvestableArray
@property(nonatomic) long long clusterAgentId;
@property(nonatomic) long long realAgentId;
- (id) JSONObject;
- (BOOL) isValid;
@end
