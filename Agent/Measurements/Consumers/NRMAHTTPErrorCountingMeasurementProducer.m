//
//  NRHTTPErrorCountingMetricProducer.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/26/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHTTPErrorCountingMeasurementProducer.h"
#import "NRMAHTTPErrorMeasurement.h"
#import "NRMAHarvestController.h"
#import "NRLogger.h"
#import "NRMAHarvestController.h"
@implementation NRMAHTTPErrorCountingMeasurementProducer

- (id) init
{
    self = [super initWithType:NRMAMT_HTTPError];
    if (self) {
        
    }
    return self;
}

- (void) consumeMeasurement:(NRMAMeasurement *)measurement
{
    
    if (![NRMAHarvestController configuration].collect_network_errors) {
        //error collection is disabled.
        return;
    }
    
    NRMAHTTPErrorMeasurement* errorMeasurement;
    if (![measurement isKindOfClass:[NRMAHTTPErrorMeasurement class]]) {
        return;
    }
    errorMeasurement = (NRMAHTTPErrorMeasurement*)measurement;
    NRMAHarvestableHTTPError* error = [[NRMAHarvestableHTTPError alloc] initWithString:errorMeasurement.url
                                                                            statusCode:errorMeasurement.statusCode
                                                                          responseBody:errorMeasurement.responseBody
                                                                            stackTrace:errorMeasurement.stackTrace
                                                                            parameters:errorMeasurement.parameters];
    error.startTimeSeconds = ((long long)errorMeasurement.errorTime) /1000;
    error.endTimeSeconds = ((long long)errorMeasurement.errorTime)/1000;
    error.appData = errorMeasurement.appData;
    NRLOG_VERBOSE(@"NRHTTPErrorCountingMetricProducer new error for %@",errorMeasurement.url);
    
    [NRMAHarvestController addHarvestableHTTPError:error];
    
    return;
}

@end
