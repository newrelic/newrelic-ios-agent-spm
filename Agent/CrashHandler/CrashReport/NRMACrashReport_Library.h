//
//  NRMACrashReport_Library.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/6/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMACrashReport_CodeType.h"
#import "NRMAJSON.h"

#define kNRMA_CR_baseAddressKey @"baseAddress"
#define kNRMA_CR_imageNameKey   @"imageName"
#define kNRMA_CR_imageSizeKey   @"imageSize"
#define kNRMA_CR_imageUuidKey   @"imageUuid"
#define kNRMA_CR_codeTypeKey    @"codeType"

@interface NRMACrashReport_Library : NSObject <NRMAJSONABLE>
@property(strong) NSString* baseAddress;
@property(strong) NSString* imageName;
@property(strong) NSNumber* imageSize;
@property(strong) NSString* imageUuid;
@property(strong) NRMACrashReport_CodeType* codeType;

- (instancetype) initWithBaseAddress:(NSString*)baseAddress
                           imageName:(NSString*)imageName
                           imageSize:(NSNumber*)imageSize
                           imageUuid:(NSString*)imageUuid
                            codeType:(NRMACrashReport_CodeType*)codeType;
@end
