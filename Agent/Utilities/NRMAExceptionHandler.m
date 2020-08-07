//
//  NRExceptionHandler.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/28/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAExceptionHandler.h"
#import "NRMAMeasurements.h"
#import "NRConstants.h"
#import "NRMATaskQueue.h"
#import "NRMAMetric.h"

@implementation NRMAExceptionHandler


+ (void) logException:(NSException*)exception
                class:(NSString*)cls
             selector:(NSString*)sel
{
    if (exception == nil || cls == nil || sel == nil) {
        NRLOG_ERROR(@"%@ called with invalid parameters", NSStringFromClass([self class]));
        return;
    }

    if (![exception isKindOfClass:[NSException class]]) {
        NRLOG_ERROR(@"%@ called with invalid parameter %@",NSStringFromClass([self class]),exception);
        return;
    }

    if (![cls isKindOfClass:[NSString class]]) {
        NRLOG_ERROR(@"%@ called with invalid parameter as NSString",NSStringFromClass([self class]));
        return;
    }

    if (![sel isKindOfClass:[NSString class]]) {
        NRLOG_ERROR(@"%@ called with invalid parameter as NSString",NSStringFromClass([self class]));
        return;
    }


    @try {
    [NRMATaskQueue queue:[[NRMAMetric alloc] initWithName:[NSString stringWithFormat:@"%@/Exception/%@/%@/%@",kNRAgentHealthPrefix,cls,sel,exception.name]
                               value:@1
                           scope:nil]];
    } @catch (NSException* exception) {
        //something when horribly wrong.
    }
}

@end
