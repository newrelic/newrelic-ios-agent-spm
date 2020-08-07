//
//  NRMAActivityNameGenerator.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 6/30/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface NRMAActivityNameGenerator : NSObject
+ (NSString*) generateActivityNameFromClass:(Class)cls selector:(SEL)selector;
@end
