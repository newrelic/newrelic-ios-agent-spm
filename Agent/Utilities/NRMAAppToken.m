//
//  NRMAAppToken.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/19/18.
//  Copyright © 2018 New Relic. All rights reserved.
//

#import "./NRMAAppToken.h"
#import "NRLogger.h"

@implementation NRMAAppToken

- (instancetype) initWithApplicationToken:(NSString*)appToken {
    self = [super init];
    if (self) {
        _value = appToken;
       _regionCode = [self parseRegion:appToken];
    }
    return self;
}



- (NSString*) parseRegion:(NSString*)appToken {
    NSError* regexError = nil;
    NSRegularExpression* regularExpression = [[NSRegularExpression alloc] initWithPattern:@"^.+?x"
                                                                                          options:0
                                                                                    error:&regexError];

    if (regexError) {
        NRLOG_VERBOSE(@"failed to initialize REGEX: %@", regexError.localizedDescription);
        return @"";
    }

    NSTextCheckingResult* match = [regularExpression firstMatchInString:appToken
                                                                options:0
                                                                  range:NSMakeRange(0, appToken.length)];

    if (match == nil || match.range.location == NSNotFound) {
        return @"";
    }

    NSString* matchString = [appToken substringWithRange:match.range];

    for (int i = matchString.length-1 ; i >= 0; i--) {
        if (appToken.UTF8String[i] != 'x') {
            return [matchString substringWithRange:NSMakeRange(0, (NSUInteger)i+1)];
        }
    }
    
    return @"";
}

@end
