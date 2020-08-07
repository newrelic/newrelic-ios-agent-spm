//
//  NRMAHarvestResponse.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/27/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>



#define OK                     200
#define UNAUTHORIZED           401
#define FORBIDDEN              403
#define NOT_FOUND              404
#define ENTITY_TOO_LARGE       413
#define INVALID_AGENT_ID       450
#define UNSUPPORTED_MEDIA_TYPE 415
#define UNKNOWN                 -1

@interface NRMAHarvestResponse : NSObject
{
    NSString* _responseBody;
}
@property(assign) int statusCode;
@property(strong) NSString* responseBody;
@property(strong) NSError* error;

- (int) getResponseCode;
- (BOOL) isDisableCommand;
- (BOOL) isError;
- (BOOL) isOK;

@end
