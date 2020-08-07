//
//  Copyright © 2018 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAUserAction.h"

@implementation NRMAUserAction

-(instancetype) init {
    self = [super init];
    if(self) {
        _timeCreated = nil;
        _actionType = @"";
        _associatedClass = @"";
        _associatedMethod = @"";
        _elementLabel = @"";
        _accessibilityId = @"";
        _elementFrame = @"";
        _interactionCoordinates = @"";
    }
    return self;
}

@end
