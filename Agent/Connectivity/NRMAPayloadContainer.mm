//
//  NRMAPayloadContainer.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/6/18.
//  Copyright © 2018 New Relic. All rights reserved.
//

#import <c++/v1/memory>
#include <Connectivity/Payload.hpp>
#import "NRMAPayloadContainer.h"

@implementation NRMAPayloadContainer
{
    std::unique_ptr<NewRelic::Connectivity::Payload> _payload;
}
- (instancetype)initWithPayload:(std::unique_ptr<NewRelic::Connectivity::Payload>)payload {
    self = [super init];
    if (self != nil) {
        _payload = std::move(payload);
    }
    return self;
}

- (std::unique_ptr<NewRelic::Connectivity::Payload>) pullPayload {
    return std::move(_payload);
}

@end
