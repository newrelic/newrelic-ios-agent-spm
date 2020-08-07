//
//  Copyright © 2018 New Relic. All rights reserved.
//

#import "NRMAUserActionBuilder.h"
#import "NRLogger.h"
#import "NRConstants.h"

@interface NRMAUserActionBuilder (protected)
-(instancetype) init;
@end

@implementation NRMAUserActionBuilder

-(instancetype) init {
    self = [super init];
    if(self) {
        _gestureBeingBuilt = [[NRMAUserAction alloc] init];
    }
    return self;
}

-(void) withActionType:(NSString*)actionType {
    _gestureBeingBuilt.actionType = actionType;

    if([actionType isEqualToString:kNRMAUserActionAppLaunch]){
        _gestureBeingBuilt.associatedClass = @"AppDelegate";
        _gestureBeingBuilt.associatedMethod = @"ApplicationWillEnterForeground";

    }
    if([actionType isEqualToString:kNRMAUserActionAppBackground]){
        _gestureBeingBuilt.associatedClass = @"AppDelegate";
        _gestureBeingBuilt.associatedMethod = @"ApplicationWillEnterBackground";
    }
}

-(void)fromClass:(NSString*)className {
    _gestureBeingBuilt.associatedClass = className;
}

-(void)fromMethod:(NSString*)methodName {
    _gestureBeingBuilt.associatedMethod = methodName;
}

-(void) fromUILabel:(NSString*)uiLabel {
    _gestureBeingBuilt.elementLabel = uiLabel;
}

-(void) withAccessibilityId:(NSString*)accessibilityId {
    _gestureBeingBuilt.accessibilityId = accessibilityId;
}

-(void) withElementFrame:(NSString*)elementFrame {
     _gestureBeingBuilt.elementFrame = elementFrame;
}

-(void) atCoordinates:(NSString*)interactionCoordinates {
    _gestureBeingBuilt.interactionCoordinates = interactionCoordinates;
}

-(NRMAUserAction*) build {
    _gestureBeingBuilt.timeCreated = [[NSDate alloc] init];
    
    if([_gestureBeingBuilt.actionType length] == 0
       || [_gestureBeingBuilt.associatedMethod length] == 0
       || [_gestureBeingBuilt.associatedClass length] == 0) {
        NRLOG_VERBOSE(@"Failed to create gesture.");
        return nil;
    }
    
    return _gestureBeingBuilt;
}

+(NRMAUserAction*)buildWithBlock:(void (^)(NRMAUserActionBuilder *))builderBlock {
    NRMAUserActionBuilder* builder = [[NRMAUserActionBuilder alloc] init];
    builderBlock(builder);
    return [builder build];
}

@end
