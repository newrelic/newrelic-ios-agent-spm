//
//  NRMAClassNode.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/18/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NRMAClassNode : NSObject
@property(strong, nonatomic)   NSString* name;
@property(strong, nonatomic)   NSMutableSet* children;

- (instancetype) initWithName:(NSString *)name;
@end
