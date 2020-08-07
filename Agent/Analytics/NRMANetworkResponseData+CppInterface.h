//
//  Copyright © 2018 New Relic. All rights reserved.
//

#import "NRMANetworkResponseData.h"
#import "Analytics/NetworkResponseData.hpp"

#ifndef NRMANetworkResponseData_CppInterface_h
#define NRMANetworkResponseData_CppInterface_h

@interface NRMANetworkResponseData (CppInterface)
-(NewRelic::NetworkResponseData*) getNetworkResponseData;
@end

#endif /* NRMANetworkResponseData_CppInterface_h */

