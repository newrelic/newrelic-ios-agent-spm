//
//  NRMAConnectInformation.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/27/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NRMAHarvestableArray.h"
#import "NRMAApplicationInformation.h"
#import "NRMADeviceInformation.h"

#define kNRMAConnectionInfoApplicationInfo @"com.newrelic.connectioninformation.applicationinfo"
#define kNRMAConnectionInfoDeviceInfo @"com.newrelic.connectioninformation.deviceinfo"
@interface NRMAConnectInformation : NRMAHarvestableArray
@property(strong) NRMAApplicationInformation* applicationInformation;
@property(strong) NRMADeviceInformation*      deviceInformation;


- (NSDictionary*) asDictionary;
- (id) initWithDictionary:(NSDictionary*)dictionary;
- (NSString *)toApplicationIdentifier;

@end
