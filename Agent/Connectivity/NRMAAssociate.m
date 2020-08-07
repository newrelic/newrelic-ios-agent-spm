//
//  NSObject+NRMASetAssociatedObject.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/6/18.
//  Copyright © 2018 New Relic. All rights reserved.
//

#import "NRMAAssociate.h"
#import <objc/runtime.h>

@implementation NRMAAssociate

+ (void)attach:(id)value
            to:(id)object
          with:(NSString *)key {
        objc_setAssociatedObject(object,
                                 [key cStringUsingEncoding:NSUTF8StringEncoding],
                                 value,
                                 OBJC_ASSOCIATION_RETAIN);

    }

+ (id)retrieveFrom:(id)object
              with:(NSString *)key {
    return objc_getAssociatedObject(object,
                                    [key cStringUsingEncoding:NSUTF8StringEncoding]);
}

+ (void)removeFrom:(id)object
              with:(NSString *)key {
    objc_setAssociatedObject(object,
                             [key cStringUsingEncoding:NSUTF8StringEncoding],
                             nil,
                             OBJC_ASSOCIATION_ASSIGN);
}

@end
