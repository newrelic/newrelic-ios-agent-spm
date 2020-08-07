//
//  Copyright © 2018 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NRMANetworkRequestData : NSObject

-(id) initWithRequestUrl:(NSURL*)requestUrl
              httpMethod:(NSString*)requestMethod
          connectionType:(NSString*)connectionType
             contentType:(NSString*)contentType
               bytesSent:(NSInteger)bytesSent;

-(void) dealloc;

@end
