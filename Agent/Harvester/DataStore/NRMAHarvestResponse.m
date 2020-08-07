//
//  NRMAHarvestResponse.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/27/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestResponse.h"


static const NSString* kDISABLE_STRING = @"DISABLE_NEW_RELIC";

@implementation NRMAHarvestResponse

- (int) getResponseCode
{
    if ([self isOK]) {
        return OK;
    }
    switch (self.statusCode) {
        case UNAUTHORIZED:
        case ENTITY_TOO_LARGE:
        case FORBIDDEN:
        case INVALID_AGENT_ID:
        case UNSUPPORTED_MEDIA_TYPE:
            return self.statusCode;
            break;
        default:
            return UNKNOWN;
            break;
    }
}

- (BOOL) isDisableCommand
{
    return FORBIDDEN == [self getResponseCode] && [kDISABLE_STRING isEqualToString:self.responseBody];
}


- (BOOL) isError
{
    return self.error != nil || self.statusCode >= 400;
}
- (BOOL) isOK
{
    return ![self isError];
}


@end
