//
// Created by Bryce Buchanan on 2/9/15.
// Copyright (c) 2015 New Relic. All rights reserved.
//

#import "NRMAHarvestableAnalytics.h"

#import "NRLogger.h"

@implementation NRMAHarvestableAnalytics
- (id) initWithAttributeJSON:(NSString*)attributeJSON EventJSON:(NSString*)eventJSON{


    self = [super init];
    if (self) {
        NSError* error = nil;
        NSData* attributeJSONData = [attributeJSON dataUsingEncoding:NSUTF8StringEncoding];

        if (attributeJSONData.length > 0) {
            self.sessionAttributes = [NSJSONSerialization JSONObjectWithData:attributeJSONData
                                                                     options:0
                                                                       error:&error];
        } 


        if(error != nil) {
            //failure
            NRLOG_ERROR(@"Failed to convert analytic attributes string to havestable object: %@",error.localizedDescription);
            return nil;
        }

        NSData* eventJSONData = [eventJSON dataUsingEncoding:NSUTF8StringEncoding];
        if (eventJSONData.length > 0) {
            self.events = [NSJSONSerialization JSONObjectWithData:eventJSONData
                                                      options:0
                                                        error:&error];
        }

        if  (error != nil) {
            NRLOG_ERROR(@"Failed to convert analytic events string to havestable object: %@",error.localizedDescription);
            return nil;

        }
    }
    return self;
}

-(id) JSONObject {
    return @[self.sessionAttributes,self.events];
}
@end
