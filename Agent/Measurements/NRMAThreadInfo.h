//
//  NRMAThreadInfo.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/20/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NRMAThreadInfo : NSObject
@property(readonly) NSString* name;
@property(readonly) unsigned int identity;
- (id) init;
- (NSString*) toString;
- (void)  setThreadName:(NSString*)threadname;

//clears the thread name pool used to name unnamed threads
//should probably be cleared after a interaction trace completes
+ (void) clearThreadNames;
@end
