//
//  NewRelicAgent+Development.h
//
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NewRelic.h"


@interface NewRelicAgent(Development)
/*
 Starts the agent and has it report to the given collector url for development purposes.
 */
+ (void)startWithApplicationToken:(NSString*)appToken
              andCollectorAddress:(NSString*)url
         andCrashCollectorAddress:(NSString *)crashCollectorUrl;

// + (BOOL) harvestNow;
// triggers a harvest immidediately. Used for testing.
// returns YES if it's able to execute a harvest request
// returns NO if it's not in the correct harvest state and cannot execute a harvest
+ (BOOL) harvestNow;

@end

