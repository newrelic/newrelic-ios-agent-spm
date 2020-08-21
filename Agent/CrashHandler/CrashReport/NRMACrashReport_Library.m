//
//  NRMACrashReport_Library.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/6/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMACrashReport_Library.h"

@implementation NRMACrashReport_Library
- (instancetype) initWithBaseAddress:(NSString*)baseAddress
                           imageName:(NSString*)imageName
                           imageSize:(NSNumber*)imageSize
                           imageUuid:(NSString*)imageUuid
                            codeType:(NRMACrashReport_CodeType*)codeType
{
    self = [super init];
    if (self) {
        _baseAddress = baseAddress;
        _imageName = imageName;
        _imageSize = imageSize;
        _imageUuid = imageUuid;
        _codeType = codeType;
    }
    return self;
}
- (id) JSONObject
{
    /*
     @property(strong) NSString* baseAddress;
     @property(strong) NSString* imageName;
     @property(strong) NSString* imageSize;
     @property(strong) NSString* imageUuid;
     @property(strong) NRMACrashReport_CodeType* codeType;
     */
    NSMutableDictionary* jsonDictionary = [[NSMutableDictionary alloc] init];
    jsonDictionary[kNRMA_CR_baseAddressKey] = self.baseAddress ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_imageNameKey] = self.imageName ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_imageSizeKey] = self.imageSize ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_imageUuidKey] = (id) self.imageUuid ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_codeTypeKey] = [self.codeType JSONObject] ?: (id) [NSNull null];
    return jsonDictionary;
}
@end
