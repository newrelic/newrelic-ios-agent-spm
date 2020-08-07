//
//  NRMAHTTPErrorMeasurement.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/26/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHTTPErrorMeasurement.h"
#import "NewRelicInternalUtils.h"

@implementation NRMAHTTPErrorMeasurement

- (id) initWithURL:(NSString*)URL statusCode:(int)statusCode
{
    self = [super initWithType:NRMAMT_HTTPError];
    if (self) {
        _url = URL;
        _statusCode = statusCode;
        _name = URL;
        self.startTime = NRMAMillisecondTimestamp();
    }
    return self;
}


@end
