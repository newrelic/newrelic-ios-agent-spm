//
//  NRMAGestureProcessor.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/11/16.
//  Copyright © 2016 New Relic. All rights reserved.
//



#import "NRMAGestureProcessor.h"
#import <UIKit/UIKit.h>
@implementation NRMAGestureProcessor

+ (NSString*) getLabel:(id)control
{
    NSMutableDictionary* dictionary = [NSMutableDictionary new];
    // button
    if([[control class] isSubclassOfClass:[UIButton class]]) {
        NSString* label = ((UIButton*)control).currentTitle;
        if (label.length) {
            return label;
        }
    }
    return nil;
}
+ (NSString*) getAccessibility:(id)control
{
    if ([[control class] isSubclassOfClass:[NSObject class]]) {
        NSString* accessibility = [((NSObject*)control) accessibilityLabel];
        if (accessibility.length) {
            return accessibility;
        }

    }

    return nil;
}

+ (NSString*) getFrame:(id)control
{
    if ([[control class] isSubclassOfClass:[UIView class]]) {
        CGPoint point = [((UIView*)control).superview convertPoint:((UIView*)control).frame.origin
                                                          fromView:nil];
        return NSStringFromCGRect(CGRectMake(point.x, point.y, ((UIView*)control).frame.size.width, ((UIView*)control).frame.size.height));
        
    }
    
    return nil;
}

+ (NSString*) getResponderChain:(id)control
{
    if (![control isKindOfClass:[UIResponder class]]) return nil;

    NSMutableArray* responders = [NSMutableArray new];

    id currentResponder = control;
    while (currentResponder != nil) {
        [responders addObject:NSStringFromClass([currentResponder class])];
        if ([currentResponder isKindOfClass:[UIViewController class]]) {
            break;
        }
        currentResponder = [currentResponder nextResponder];
    }

    return [responders componentsJoinedByString:@"/"];
}

+ (NSString*) getTouchCoordinates:(UIEvent*)event
{
    if (![event isKindOfClass:[UIEvent class]]) return nil;
    NSMutableArray* readableTouch = [NSMutableArray new];
    NSArray* touches = [[event allTouches] allObjects];
    for(UITouch* touch in touches) {
        [readableTouch addObject:NSStringFromCGPoint([touch locationInView:[[UIApplication sharedApplication] keyWindow]])];
    }

    return [readableTouch componentsJoinedByString:@","];
}
@end
