//
//  NRMAHTTPErrorMeasurementProducer.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/26/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMeasurementProducer.h"

@interface NRMAHTTPErrorMeasurementProducer : NRMAMeasurementProducer


- (void) produceMeasurementWithURL:(NSString*)URL
                        httpMethod:(NSString*)httpMethod
                       timeOfError:(double)timeError
                        statusCode:(NSInteger)statusCode
                          response:(NSString*)responseBody
                           wanType:(NSString*)wanType
                           appData:(NSString*)appData
                        parameters:(NSDictionary*)parameters;
@end
