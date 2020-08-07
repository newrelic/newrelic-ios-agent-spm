//
// Created by Bryce Buchanan on 7/6/17.
// Copyright (c) 2017 New Relic. All rights reserved.
//

#import "NRMAExceptionReportAdaptor.h"
#import "NewRelicInternalUtils.h"
#import "NRMABool.h"


@implementation NRMAExceptionReportAdaptor
- (instancetype) initWithReport:(std::shared_ptr<NewRelic::Hex::Report::HexReport>)context {
    self = [super init];
    if(self) {
        _report = context;
    }
    return self;
}

- (std::shared_ptr<NewRelic::Hex::Report::HexReport>) report {
    return _report;
}

- (void) addAttributes:(NSDictionary*)attributes {
    for (NSString* key in attributes) {
        NSObject* obj = attributes[key];
        if ([obj isKindOfClass:[NSString class]]) {
            [self addKey:key
             stringValue:(NSString*)obj];
        } else if ([obj isKindOfClass:[NSNumber class]]) {
            [self addKey:key
             numberValue:(NSNumber*)obj];
        } else if ([obj isKindOfClass:[NRMABool class]]) {
            [self addKey:key
               boolValue:(NRMABool*)obj];
        }
    }
}

- (void) addKey:(NSString*)key
    numberValue:(NSNumber*)num
{

    //objcType returns a char*, but all primitives are denoted by a single character
    if ([NewRelicInternalUtils isInteger:num]) {
        _report->setAttribute(key.UTF8String, [num longLongValue]);
    } else if([NewRelicInternalUtils isFloat:num]) {
        _report->setAttribute(key.UTF8String, [num doubleValue]);
    }
}

- (void) addKey:(NSString*)key
    stringValue:(NSString*)string {
    _report->setAttribute(key.UTF8String, (string.UTF8String));
}

- (void) addKey:(NSString*)key
      boolValue:(NRMABool*)boolean {
    _report->setAttribute(key.UTF8String, (bool)boolean.value);
}
@end
