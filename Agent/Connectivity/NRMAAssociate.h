//
//  NSObject+NRMASetAssociatedObject.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/6/18.
//  Copyright © 2018 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NRMAAssociate : NSObject
+ (void)attach:(id)value
            to:(id)object
          with:(NSString*)key;
+ (id)retrieveFrom:(id)object with:(NSString*)key;
+ (void)removeFrom:(id)object with:(NSString*)key;
@end
