//
//  NRMAHarvestableHTTPError.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/26/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvestableHTTPError.h"
#import <CommonCrypto/CommonCrypto.h>
#import "NRMAHarvestController.h"
#import "NRMABase64.h"
@implementation NRMAHarvestableHTTPError
@synthesize responseBody = _responseBody;

- (id)initWithString:(NSString *)url
          statusCode:(int)statusCode
        responseBody:(NSString *)responseBody
          stackTrace:(NSString *)stackTrace
          parameters:(NSDictionary *)parameters
{
    self = [super init];
    if (self) {
        self.url = url;
        self.statusCode = statusCode;
        self.responseBody = responseBody;
        self.stackTrace = stackTrace;
        self.parameters = parameters;
        self.count = 1;
        _digest = [self sha1];
    }
    return  self;
}

- (void) setResponseBody:(NSString *)responseBody
{
    _responseBody = responseBody;
    if (responseBody.length > [NRMAHarvestController configuration].response_body_limit) {
        _responseBody = [responseBody substringWithRange:NSMakeRange(0, [NRMAHarvestController configuration].response_body_limit)];
    }
}

- (NSString*) responseBody
{
    return _responseBody;
}
- (NSString*)sha1 {
    NSMutableData* data = [NSMutableData data];

    [data appendData:[self.url dataUsingEncoding:NSUTF8StringEncoding]];

    char statusCodeBuf[8];

    snprintf(statusCodeBuf, 8, "%d",self.statusCode);
    
    [data appendBytes:statusCodeBuf length:8];
    
//    if ([self.stackTrace length]) {
//        [data appendData:[self.stackTrace dataUsingEncoding:NSUTF8StringEncoding]];
//    }
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes,(CC_LONG)data.length,digest);
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x",digest[i]];
    }
    return output;
}

- (id) JSONObject {
    NSMutableArray* jsonArray = [[NSMutableArray alloc] initWithCapacity:6];
    [jsonArray addObject:self.url?:@""];
    [jsonArray addObject:@(self.statusCode)];
    [jsonArray addObject:@(self.count)];

    if (self.responseBody.length) {
        //the server expects the response body to be base 64 encoded.
        NSString* base64Str = [NRMABase64 encodeFromData:[self.responseBody  dataUsingEncoding:NSUTF8StringEncoding]];
        [jsonArray addObject:base64Str.length?base64Str:self.responseBody];

    } else {
        [jsonArray addObject:@""];
    }

    [jsonArray addObject:@""];
    [jsonArray  addObject:self.parameters?:[NSDictionary dictionary]];
    [jsonArray addObject:self.appData?:@""];
    return jsonArray;
}

@end
