//
//  Copyright © 2018 New Relic. All rights reserved.
//

#import "NRMANetworkRequestData.h"
#import "Analytics/NetworkRequestData.hpp"

#ifndef NRMANetworkRequestData_CppInterface_h
#define NRMANetworkRequestData_CppInterface_h

@interface NRMANetworkRequestData (CppInterface)
-(NewRelic::NetworkRequestData*) getNetworkRequestData;
@end

#endif /* NRMANetworkRequestData_CppInterface_h */
