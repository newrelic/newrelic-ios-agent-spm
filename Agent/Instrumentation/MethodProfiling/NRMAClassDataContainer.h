//
//  NRMAClassDataContainer.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/15/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NRMAClassDataContainer : NSObject <NSCopying>
@property(strong,readonly) NSString* name;
@property(unsafe_unretained,readonly) Class storedClass; //if not unsafe_unretained bad things happen!


- (instancetype) initWithCls:(Class)cls className:(NSString*)name;

@end
