//
//  Copyright © 2018 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMANetworkRequestData.h"
#import "Analytics/NetworkRequestData.hpp"
#import "NewRelicInternalUtils.h"

@interface NRMANetworkRequestData () {
    NewRelic::NetworkRequestData* wrappedNetworkRequestData;
}
@end

@implementation NRMANetworkRequestData

-(id) initWithRequestUrl:(NSURL*)requestUrl
              httpMethod:(NSString*)requestMethod
          connectionType:(NSString*)connectionType
             contentType:(NSString*)contentType
               bytesSent:(NSInteger)bytesSent{
    self = [super init];
    if(self){
        NSString* requestDomain = requestUrl.host;
        NSString* requestPath = requestUrl.path;

        NSString* safeUrlBuilder = [[NSMutableString alloc] init];

        if (requestUrl.scheme) {
            safeUrlBuilder = [safeUrlBuilder stringByAppendingString:[NSString stringWithFormat:@"%@://",requestUrl.scheme]];
        }

        if (requestDomain) {
            safeUrlBuilder = [safeUrlBuilder stringByAppendingString:requestDomain];
        }

        if (requestPath) {
            safeUrlBuilder = [safeUrlBuilder stringByAppendingString:requestPath];
        }

        NSString* safeUrl = [NewRelicInternalUtils normalizedStringFromString:safeUrlBuilder];
        
        wrappedNetworkRequestData = new NewRelic::NetworkRequestData(safeUrl.UTF8String,
                                                                     requestDomain.UTF8String,
                                                                     requestPath.UTF8String,
                                                                     requestMethod.UTF8String,
                                                                     connectionType.UTF8String,
                                                                     contentType.UTF8String,
                                                                     bytesSent);
        if(!wrappedNetworkRequestData) self = nil;
    }
    return self;
}

-(NewRelic::NetworkRequestData*) getNetworkRequestData {
    return wrappedNetworkRequestData;
}

-(void) dealloc {
    delete wrappedNetworkRequestData;
}

@end
