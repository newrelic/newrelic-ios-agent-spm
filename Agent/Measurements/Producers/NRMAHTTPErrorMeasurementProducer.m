//
//  NRMAHTTPErrorMeasurementProducer.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/26/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHTTPErrorMeasurementProducer.h"
#import "NRMAHTTPErrorMeasurement.h"
#import "NewRelicInternalUtils.h"
#import "NRMAExceptionHandler.h"

@implementation NRMAHTTPErrorMeasurementProducer

- (id) initWithType:(NRMAMeasurementType)type {
    @throw [NRMAMeasurementException exceptionWithName:NRMAMeasurementTypeConsistencyError
                                              reason:@"Use -init to initialize NRMAHTTPErrorMeasurementProducer"
                                            userInfo:nil];
}
- (id) init
{
    return [super initWithType:NRMAMT_HTTPError];
}

- (void) produceMeasurementWithURL:(NSString*)url
                        httpMethod:(NSString*)httpMethod
                       timeOfError:(double)timeError
                        statusCode:(NSInteger)statusCode
                          response:(NSString*)responseBody
                           wanType:(NSString*)wanType
                           appData:(NSString*)appData
                        parameters:(NSDictionary*)parameters
{
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif
        NRMAHTTPErrorMeasurement *measurement = [[NRMAHTTPErrorMeasurement alloc] initWithURL:[NewRelicInternalUtils normalizedStringFromString: url] statusCode:(int)statusCode];

        measurement.parameters = parameters;
        measurement.httpMethod = httpMethod;
        measurement.responseBody = responseBody;
        measurement.errorTime = timeError;
        measurement.wanType = wanType;
        measurement.appData = appData;
        measurement.threadInfo = [[NRMAThreadInfo alloc] init];
        [self produceMeasurement:measurement];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    }
    @catch (NSException *exception) {
        [NRMAExceptionHandler logException:exception
                                   class:NSStringFromClass([self class])
                                selector:NSStringFromSelector(@selector(produceMeasurementWithURL:httpMethod:timeOfError:statusCode:response:wanType:appData:parameters:))];
    }
#endif

}

@end
