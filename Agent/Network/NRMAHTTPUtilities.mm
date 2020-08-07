//
//  NRMANetworkUtilites.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/28/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#include <iostream>
#include <sstream>

#include <Connectivity/Facade.hpp>

#import "NRMABase64.h"
#import "NRMAHTTPUtilities.h"
#import "NRMAHarvestController.h"
#import "NRMAFlags.h"
#import "NRMAPayloadContainer+cppInterface.h"
#import "NRMAAssociate.h"
#import "NRMANetworkFacade.h"
#import "NRMAPayloadContainer.h"

@implementation NRMAHTTPUtilities
+ (NSMutableURLRequest*) addCrossProcessIdentifier:(NSURLRequest*)request
{

    NSMutableURLRequest* mutableRequest = [self makeMutable:request];

    NSString* xprocess = [NRMAHarvestController configuration].cross_process_id;

    if (xprocess.length) {
        [mutableRequest setValue:xprocess
              forHTTPHeaderField:NEW_RELIC_CROSS_PROCESS_ID_HEADER_KEY];
    }

    return mutableRequest;
}

+ (NSMutableURLRequest*) makeMutable:(NSURLRequest*)request
{
    __autoreleasing NSMutableURLRequest* mutableRequest = nil;
    if ([request isKindOfClass:[NSMutableURLRequest class]]) {
        mutableRequest = (NSMutableURLRequest*)request;
    } else {
        mutableRequest = [request mutableCopy]; //a copy is retained
    }
    return mutableRequest;
}


+ (NSMutableURLRequest*) addConnectivityHeaderAndPayload:(NSURLRequest*)request {
    NSMutableURLRequest* mutableRequest = [NRMAHTTPUtilities makeMutable:request];
    [NRMAHTTPUtilities attachPayload:[NRMAHTTPUtilities addConnectivityHeader:mutableRequest]
                                  to:mutableRequest];
    return mutableRequest;

}

+ (NRMAPayloadContainer*) addConnectivityHeader:(NSMutableURLRequest*)request {

    if([NRMAFlags shouldEnableDistributedTracing]) {
        std::unique_ptr<NewRelic::Connectivity::Payload> payload = nullptr;
        payload = NewRelic::Connectivity::Facade::getInstance().startTrip();

        if (payload != nullptr) {
            auto json = payload->toJSON();
            std::stringstream s;
            s << json;

            NSString* string = [NSString stringWithCString:s.str().c_str()
                                                  encoding:NSUTF8StringEncoding];

            if (string.length) {
                [request setValue:[NRMABase64 encodeFromData:[string dataUsingEncoding:NSUTF8StringEncoding]]
                      forHTTPHeaderField:NEW_RELIC_DISTRIBUTED_TRACING_HEADER_KEY];
            }

            return [[NRMAPayloadContainer alloc] initWithPayload:std::move(payload)];
        }
    }
    return nil;
}

+ (void) attachPayload:(NRMAPayloadContainer*)payload to:(id)object{
    [NRMAAssociate attach:payload to:object with:kNRMA_ASSOCIATED_PAYLOAD_KEY];

}


+ (std::unique_ptr<NewRelic::Connectivity::Payload>) retreivePayload:(id)object {
    id associatedObject = [NRMAAssociate retrieveFrom:object
                                    with:kNRMA_ASSOCIATED_PAYLOAD_KEY];

    [NRMAAssociate removeFrom:object
                         with:kNRMA_ASSOCIATED_PAYLOAD_KEY];

    if ([associatedObject isKindOfClass:[NRMAPayloadContainer class]]) {

        return [((NRMAPayloadContainer* )associatedObject) pullPayload];
    }


    return std::unique_ptr<NewRelic::Connectivity::Payload>(nullptr);
}

@end
