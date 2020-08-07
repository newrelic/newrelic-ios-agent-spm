//
//  NRMAHarvestable.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/26/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAHarvestableProtocol.h"
#import "NRMAJSON.h"

@interface NRMAHarvestable : NSObject <NRMAHarvestableProtocol,NRMAJSONABLE>
{
    
}

@property(readonly) NRMAHarvestableType type;
- (id) initWithType:(NRMAHarvestableType)type;
- (void) notEmpty:(NSString*)argument;
- (void) notNull:(id)argument;
- (NSString*) optional:(NSString*)argument;
@end

