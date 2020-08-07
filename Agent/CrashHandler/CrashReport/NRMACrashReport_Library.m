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
    [jsonDictionary setObject:self.baseAddress?:[NSNull null] forKey:kNRMA_CR_baseAddressKey];
    [jsonDictionary setObject:self.imageName?:[NSNull null] forKey:kNRMA_CR_imageNameKey];
    [jsonDictionary setObject:self.imageSize?:[NSNull null] forKey:kNRMA_CR_imageSizeKey];
    [jsonDictionary setObject:self.imageUuid?:[NSNull null] forKey:kNRMA_CR_imageUuidKey];
    [jsonDictionary setObject:[self.codeType JSONObject]?:[NSNull null] forKey:kNRMA_CR_codeTypeKey];
    return jsonDictionary;
}
@end
