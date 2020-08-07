//
//  NRMAGestureProcessor.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/11/16.
//  Copyright © 2016 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*
 * This object provides an simplified interface to collect key details from
 * UIControl objects and UIEvents which are used in TrackedGesture Events.
 */

@interface NRMAGestureProcessor : NSObject
+ (NSString*) getLabel:(id)control;
+ (NSString*) getResponderChain:(id)control;
+ (NSString*) getAccessibility:(id)control;
+ (NSString*) getTouchCoordinates:(UIEvent*)event;
+ (NSString*) getFrame:(id)control;
@end
