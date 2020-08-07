//
//  NRMAActivityNameGenerator.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 6/30/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAActivityNameGenerator.h"
#import <UIKit/UIKit.h>

static NSString const *kNRMA_ActivityVerb_Display = @"Display";

static NSString const *kNRMA_selector_viewDidLoad = @"viewDidLoad";
static NSString const *kNRMA_selector_viewWillAppear = @"viewWillAppear:";

@implementation NRMAActivityNameGenerator
+ (NSString*) generateActivityNameFromClass:(Class)cls selector:(SEL)selector
{
    NSString* name = nil;
    NSString* class = [self translationNameFromClass:NSStringFromClass(cls)];
    NSString* sel = NSStringFromSelector(selector);
    if ([cls isSubclassOfClass:[UIViewController class]]) {
        if ([kNRMA_selector_viewDidLoad isEqualToString:sel] ||
            [kNRMA_selector_viewWillAppear isEqualToString:sel]) {
            name = [NSString stringWithFormat:@"%@ %@",kNRMA_ActivityVerb_Display,class];
        }
    } else {
        name = class; 
    }

    return name;
}

+ (NSDictionary*) classNameTranslationTable
{
    static NSDictionary* __classNameLookup;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __classNameLookup = @{@"_UIModalItemAppViewController":@"UIAlertViewContainerController"};
    });
    return __classNameLookup;
}

+ (NSString*) translationNameFromClass:(NSString*)className //className nr_translateClassName(NSString* className)
{
    NSDictionary* translationTable = [self classNameTranslationTable];
    NSString* translatedName = [translationTable objectForKey:className];
    return translatedName?:className;
}


@end
