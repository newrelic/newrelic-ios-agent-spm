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
    [jsonDictionary setObject:self.arch?:[NSNull null] forKey:kNRMA_CR_archKey];
    [jsonDictionary setObject:self.typeEncoding?:[NSNull null] forKey:kNRMA_CR_typeEncodingKey];
    return jsonDictionary;
}
@end
