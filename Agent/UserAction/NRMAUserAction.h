//
//  Copyright © 2018 New Relic. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface NRMAUserAction : NSObject

@property (nonatomic, strong) NSString* actionType;
@property (nonatomic, strong) NSDate* timeCreated;
@property (nonatomic, strong) NSString* associatedMethod;
@property (nonatomic, strong) NSString* associatedClass;
@property (nonatomic, strong) NSString* elementLabel;
@property (nonatomic, strong) NSString* accessibilityId;
@property (nonatomic, strong) NSString* elementFrame;
@property (nonatomic, strong) NSString* interactionCoordinates;

@end

