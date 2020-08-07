//
//  NRMAMeasurementsEngine.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/20/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    NRMAMT_Network = 0,
    NRMAMT_HTTPError,
    NRMAMT_HTTPTransaction,
    NRMAMT_Method,
    NRMAMT_Activity,
    NRMAMT_NamedValue,
    NRMAMT_NamedEvent,
    NRMAMT_Any
} NRMAMeasurementType;

extern NSString* NSStringFromNRMAMeasurementType(NRMAMeasurementType type);
