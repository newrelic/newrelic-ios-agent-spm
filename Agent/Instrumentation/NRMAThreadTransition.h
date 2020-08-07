//
//  NRMAThreadTransition.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/9/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMATrace.h"
@interface NRMAThreadTransition : NSObject

@property(nonatomic,assign) SEL selector;
@property(nonatomic,assign) id  target;
@property(nonatomic,assign) id  argument; 
@property(nonatomic,assign) NRMATrace* parent;
@end
