//
//  NRMABool.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/19/16.
//  Copyright © 2016 New Relic. All rights reserved.
//

#import "NRMABool.h"

@implementation NRMABool
- (instancetype) initWithBOOL:(BOOL)value {
    self = [super init];
    if (self) {
        self.value = value;
    }

    return self;
}
@end
