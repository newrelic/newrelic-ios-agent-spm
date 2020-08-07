
#import <Connectivity/Payload.hpp>
#import "NRMAHTTPUtilities.h"

@interface NRMAHTTPUtilities (cppInterface)
+ (std::unique_ptr<NewRelic::Connectivity::Payload>) retreivePayload:(NSURLRequest*)request;
@end
