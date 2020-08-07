//
//  NRMAHarvestTimer.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/3/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAHarvester.h"
@interface NRMAHarvestTimer : NSObject
{
    long long lastTick;
}

@property(assign) long long period;
@property(strong,atomic) NSTimer* timer;
@property(strong) NRMAHarvester* harvester;
- (id) initWithHarvester:(NRMAHarvester*)harvester;
- (void) start;
- (void) stop;
@end
