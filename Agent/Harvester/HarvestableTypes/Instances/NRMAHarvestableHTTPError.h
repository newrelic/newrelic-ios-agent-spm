//
//  NRMAHarvestableHTTPError.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/26/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestableArray.h"

@interface NRMAHarvestableHTTPError : NRMAHarvestableArray
{
 
}
@property(atomic)           int             count;
@property(strong,nonatomic) NSString*       url;
@property(nonatomic)        int             statusCode;
@property(strong,nonatomic, setter=setResponseBody:, getter=responseBody) NSString*       responseBody;
@property(strong,nonatomic) NSString*       stackTrace;
@property(strong,nonatomic) NSDictionary*   parameters;
@property(strong,nonatomic) NSString*       appData;
@property(strong,nonatomic) NSString*       digest;
@property(nonatomic)        long long       startTimeSeconds;
@property(nonatomic)        long long       endTimeSeconds;

- (id)initWithString:(NSString *)url
          statusCode:(int)statusCode
        responseBody:(NSString *)responseBody
          stackTrace:(NSString *)stackTrace
          parameters:(NSDictionary *)parameters;
@end
