//
//  NRMACrashReport_CodeType.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/6/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMACrashReport_CodeType.h"

@implementation NRMACrashReport_CodeType

- (instancetype) initWithArch:(NSString*)arch
                 typeEncoding:(NSString*)typeEncoding
{
    self = [super init];
    if (self) {
        _arch = arch;
        _typeEncoding = typeEncoding;
    }
    return self;
}

- (id) JSONObject
{
    /*
     @property(strong) NSString* arch;
     @property(strong) NSString* typeEncoding;
     */
    NSMutableDictionary* jsonDictionary = [[NSMutableDictionary alloc] init];
    jsonDictionary[kNRMA_CR_archKey] = self.arch ?: (id) [NSNull null];
    jsonDictionary[kNRMA_CR_typeEncodingKey] = self.typeEncoding ?: (id) [NSNull null];
    return jsonDictionary;
}
@end
