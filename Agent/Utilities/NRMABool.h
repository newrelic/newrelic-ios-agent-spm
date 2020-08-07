//
//  NRMABool.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/19/16.
//  Copyright © 2016 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NRMABool : NSObject
@property(atomic) BOOL value;
- (instancetype) initWithBOOL:(BOOL)value;
@end
