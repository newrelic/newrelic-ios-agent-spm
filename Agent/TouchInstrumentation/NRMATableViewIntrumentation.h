//
//  NRMATableViewIntrumentation.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/10/16.
//  Copyright © 2016 New Relic. All rights reserved.
//
#import <Foundation/Foundation.h>

// This instrumentation is to capture touch events for TrackedGesture
// when table view cells are selected.

@interface NRMATableViewIntrumentation : NSObject
+ (BOOL) instrument;
+ (BOOL) deinstrument;
@end
