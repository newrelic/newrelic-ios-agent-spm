//
//  NRMAUUIDStore.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 12/2/15.
//  Copyright © 2015 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NRMAUUIDStore : NSObject
- (instancetype) initWithFilename:(const NSString*)filename;
- (NSString*) storedUUID;
- (BOOL) storeUUID:(NSString*)UUID;
- (void) removeStore;


@end
