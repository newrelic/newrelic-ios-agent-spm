//
//  NRMAMeasurementProtocol.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/20/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAMeasurementType.h"
#import "NRMAThreadInfo.h"
@protocol NRMAMeasurementProtocol <NSObject>
@required
- (NRMAMeasurementType) type;
- (NSString*) name;
- (double) startTime;
- (double) endTime;
- (NRMAThreadInfo*) threadInfo;
- (BOOL) isInstantaneous;
- (void) finish;
- (BOOL) isFinished;
- (double) asDouble;
@end
