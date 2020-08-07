//
// Created by Bryce Buchanan on 12/8/15.
// Copyright (c) 2015 New Relic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NRMAUDIDManager.h"
#import "NRMAUUIDStore.h"
#import "NRConstants.h"
#import "NRMAMeasurements.h"
#import "NRMAFlags.h"
#import <CommonCrypto/CommonCrypto.h>


static NSString* const kNRMASecureUDIDStore = @"com.newrelic.secureUDID";
static NSString* const kNRMAVendorIDStore   = @"com.newrelic.vendorID";

@implementation NRMAUDIDManager

+ (NSString*) UDID {
    NSString* udid = [NRMAUDIDManager getUDID];
    if (!udid) {
        @synchronized(self) {
            udid = [NRMAUDIDManager getUDID];
            if (udid == nil) {
                udid = [self noSecureUDIDFile];
                [NRMAUDIDManager setUDID:udid];
            }
        }
    }
    return udid;
}
static __strong NSString* __UDID;
+ (void) setUDID:(NSString*)udid {
    @synchronized(__UDID) {
        __UDID = udid ;
    }
}

+ (NSString*) getUDID {
    @synchronized(__UDID) {
        return __UDID;
    }
}
+ (NRMAUUIDStore*) secureUDIDStore {
static NRMAUUIDStore* __secureUDIDStore;
    if (!__secureUDIDStore) {
       __secureUDIDStore = [[NRMAUUIDStore alloc] initWithFilename:kNRMASecureUDIDStore];
    }
    return __secureUDIDStore;
}

+ (NRMAUUIDStore*) identifierForVendorStore {
    static NRMAUUIDStore* __identifierForVendorStore;
    if (!__identifierForVendorStore) {
       __identifierForVendorStore = [[NRMAUUIDStore alloc] initWithFilename:kNRMAVendorIDStore];
    }
    return __identifierForVendorStore;
}

+ (NSString*) secureUDIDFile {
    NSString* identifierForVendor = [NRMAUDIDManager getSystemIdentifier];
    if ([[NRMAUDIDManager identifierForVendorStore] storedUUID]) {
        if(identifierForVendor.length && ![[[NRMAUDIDManager identifierForVendorStore] storedUUID] isEqualToString:identifierForVendor]) {
            //detected change in vendorId, replacing secureUDID with vendorID

            //THIS IS A NEW INSTALL
            [[NSNotificationCenter defaultCenter] postNotificationName:kNRMADidGenerateNewUDIDNotification
                                                                object:nil
                                                              userInfo:@{@"UDID" : identifierForVendor}];

            [[NRMAUDIDManager secureUDIDStore] removeStore];
            [[NRMAUDIDManager identifierForVendorStore] storeUUID:identifierForVendor];
            return identifierForVendor;
        }
    } else {
        if (identifierForVendor.length) {
            [[NRMAUDIDManager identifierForVendorStore] storeUUID:identifierForVendor];
        }
    }
    return [[NRMAUDIDManager secureUDIDStore] storedUUID];
}

+ (NSString*) getSystemIdentifier {
    if ([NRMAFlags shouldSaltDeviceUUID]) {
        // use app ID as salt. This will prevent apps across bundle Ids sharing device Ids.
        NSString* clearStr = [[NRMAUDIDManager saltValue] stringByAppendingString:[UIDevice currentDevice].identifierForVendor.UUIDString];
        NSData* clearData = [clearStr dataUsingEncoding:NSUTF8StringEncoding];
        uint8_t digest[CC_SHA1_DIGEST_LENGTH];
        CC_SHA1([clearData bytes],(CC_LONG)clearData.length,digest);
        NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
        for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
            [output appendFormat:@"%02x",digest[i]];
        }
        return output;
    } else {
        return [UIDevice currentDevice].identifierForVendor.UUIDString;
    }
}

+ (NSString*) saltValue {
    return  [[NSBundle mainBundle] infoDictionary][@"CFBundleExecutable"];
}

+ (NSString*) noSecureUDIDFile {
    NSString* identifierForVendor = [NRMAUDIDManager getSystemIdentifier];
   if ([[NRMAUDIDManager identifierForVendorStore] storedUUID]) {
       if(identifierForVendor.length) {
           if(![[[NRMAUDIDManager identifierForVendorStore] storedUUID] isEqualToString:identifierForVendor]){
               //the identifier for vendor has changed!
               [[NRMAUDIDManager identifierForVendorStore] storeUUID:identifierForVendor];
               [[NSNotificationCenter defaultCenter] postNotificationName:kNRMADidGenerateNewUDIDNotification
                                                                   object:nil
                                                                 userInfo:@{ @"UDID" : identifierForVendor }];
               return identifierForVendor;
           }
       }
       return [[NRMAUDIDManager identifierForVendorStore] storedUUID];
   } else {

           [[NSNotificationCenter defaultCenter] postNotificationName:kNRMASecureUDIDIsNilNotification
                                                               object:nil];
           if (identifierForVendor.length) {
               //NEW INSTALL
               [[NRMAUDIDManager identifierForVendorStore] storeUUID:identifierForVendor];
               [[NSNotificationCenter defaultCenter] postNotificationName:kNRMADidGenerateNewUDIDNotification
                                                                   object:nil
                                                                 userInfo:@{ @"UDID" : identifierForVendor }];
               return identifierForVendor;
           } else {
               //NEW INSTALL

               [NRMAMeasurements recordAndScopeMetricNamed:[NSString stringWithFormat:@"%@/%@/%@", kNRAgentHealthPrefix, @"DeviceIdentifier", @"GeneratedUDID"]
                                                     value:@1];

               CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
               NSString* identifier = (NSString*)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
               CFRelease(uuid);

               [[NSNotificationCenter defaultCenter] postNotificationName:kNRMADidGenerateNewUDIDNotification
                                                                   object:nil
                                                                 userInfo:@{ @"UDID" : identifier }];

               [[NRMAUDIDManager secureUDIDStore] storeUUID:identifier];
               return identifier;
           }

   }
}

@end
