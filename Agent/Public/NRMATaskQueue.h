
//
//  NRMATaskQueue.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/18/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NRMATaskQueue : NSObject
@property(atomic,strong) NSMutableArray* queue;
+ (void) start;
+ (void) queue:(id)object;
+ (void) stop;

+ (void) synchronousDequeue;
@end
