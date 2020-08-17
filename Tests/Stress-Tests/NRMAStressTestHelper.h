//
//  NRMAStressTestHelper.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/11/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

extern  const int kNRMAIterations;
extern const int kNRMASemaphoreMultiplier;
@interface NRMAStressTestHelper : NSObject

+ (dispatch_queue_t) randomDispatchQueue;
@end
