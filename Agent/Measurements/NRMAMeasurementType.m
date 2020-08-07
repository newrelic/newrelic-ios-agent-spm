//
//  NRMAMeasurementType.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 9/26/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMeasurementType.h"

NSString* NSStringFromNRMAMeasurementType(NRMAMeasurementType type)
{
    switch (type) {
        case NRMAMT_Activity:
            return @"Activity";
            break;
        case NRMAMT_HTTPError:
            return @"HTTPError";
            break;
        case NRMAMT_HTTPTransaction:
            return @"HTTPTransaction";
            break;
        case NRMAMT_Method:
            return @"Method";
            break;
        case NRMAMT_NamedEvent:
            return @"Event";
            break;
        case NRMAMT_NamedValue:
            return @"Value";
            break;
        case NRMAMT_Network:
            return @"Network";
        case NRMAMT_Any:
            return @"Any";
        default:
            break;
    }
}
