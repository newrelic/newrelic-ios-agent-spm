//
//  Copyright © 2018 New Relic. All rights reserved.
//

#import "NRMAUserAction.h"

@interface NRMAUserActionBuilder : NSObject

@property (readonly) NRMAUserAction* gestureBeingBuilt;
@property (nonatomic, readonly) NSString* actionType;
@property (nonatomic, readonly) NSDate* timeCreated;

-(void) withActionType:(NSString*)actionType;
-(void) fromClass:(NSString*)className;
-(void) fromMethod:(NSString*)methodName;
-(void) fromUILabel:(NSString*)uiLabel;
-(void) withAccessibilityId:(NSString*)accessibilityId;
-(void) withElementFrame:(NSString*)elementFrame;
-(void) atCoordinates:(NSString*)interactionCoordinates;

-(NRMAUserAction*) build;
+(NRMAUserAction*) buildWithBlock:(void (^)(NRMAUserActionBuilder *)) builderBlock;

@end
