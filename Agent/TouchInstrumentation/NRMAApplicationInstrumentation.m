
// Created by Bryce Buchanan on 1/14/16.
// Copyright (c) 2016 New Relic. All rights reserved.
//

#import "NRMAApplicationInstrumentation.h"
#import "NRMAMethodSwizzling.h"
#import "NewRelicAgentInternal.h"
#import "NRMAGestureProcessor.h"
#import <objc/runtime.h>
#import "NRMAUserActionBuilder.h"
#import "NRMAFlags.h"


BOOL (*NRMA__UIApplication__sendAction_to_from_forEvent)(id,SEL,SEL,id,id,UIEvent*);

static BOOL sendAction_to_from_forEvent(id self, SEL _cmd, SEL msg, id target, id sender, UIEvent* event) {
    //instrumentation here.

    if ([NRMAFlags shouldEnableGestureInstrumentation]) {
        if (msg != NULL && target != NULL) {
            NRMAUserAction* uiGesture = [NRMAUserActionBuilder buildWithBlock:^(NRMAUserActionBuilder* builder) {
                [builder withActionType:kNRMAUserActionTap];
                [builder fromMethod:NSStringFromSelector(msg)];
                [builder fromClass:NSStringFromClass([target class])];
                [builder fromUILabel:[NRMAGestureProcessor getLabel:sender]];
                [builder withAccessibilityId:[NRMAGestureProcessor getAccessibility:sender]];
                [builder atCoordinates:[NRMAGestureProcessor getTouchCoordinates:event]];
                [builder withElementFrame:[NRMAGestureProcessor getFrame:sender]];
            }];
            [[NewRelicAgentInternal sharedInstance].gestureFacade recordUserAction:uiGesture];
        }
    }

    return NRMA__UIApplication__sendAction_to_from_forEvent(self,_cmd, msg, target,sender,event);
}

@implementation NRMAApplicationInstrumentation

+ (BOOL) instrumentUIApplication
{
    //Instrument sendAction:to:form:forEvent: on UIApplication. This allows capture of all UIControl events that occur in the app.
    id clazz = objc_getClass("UIApplication");
    if (clazz) {
        if (NRMA__UIApplication__sendAction_to_from_forEvent == NULL) {
            NRMA__UIApplication__sendAction_to_from_forEvent = NRMAReplaceInstanceMethod([UIApplication class],
            @selector(sendAction:to:from:forEvent:),(IMP)sendAction_to_from_forEvent);
            return NRMA__UIApplication__sendAction_to_from_forEvent != NULL;
        }
    }
    return NO;
}

+ (BOOL) deinstrumentUIApplication
{
    NRMA__UIApplication__sendAction_to_from_forEvent = NRMAReplaceInstanceMethod([UIApplication class],
                                                                                 @selector(sendAction:to:from:forEvent:),
                                                                                 (IMP)NRMA__UIApplication__sendAction_to_from_forEvent);
    BOOL success = NRMA__UIApplication__sendAction_to_from_forEvent == sendAction_to_from_forEvent;
    NRMA__UIApplication__sendAction_to_from_forEvent = NULL;
    return success;
}
@end
