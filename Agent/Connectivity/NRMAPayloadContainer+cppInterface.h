//
//  NRMAPayloadContainer+cppInterface.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/6/18.
//  Copyright © 2018 New Relic. All rights reserved.
//

#ifndef PayloadContainer_cppInterface_h
#define PayloadContainer_cppInterface_h

#import "NRMAPayloadContainer.h"

@interface NRMAPayloadContainer (cppInterface)
- (instancetype) initWithPayload:(std::unique_ptr<NewRelic::Connectivity::Payload>)payload;
- (std::unique_ptr<NewRelic::Connectivity::Payload>) pullPayload;
@end


#endif /* PayloadContainer_cppInterface_h */
