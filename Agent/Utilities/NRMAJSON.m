//
//  NRMAJSON.m
//  NewRelicAgent
//
//  Created by Jonathan Karon on 4/8/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAJSON.h"
#import "NRLogger.h"
#import "NRMAExceptionHandler.h"
#import <objc/runtime.h>

@implementation NRMAJSON

/* Generate JSON data from a Foundation object. If the object will not produce valid JSON then an exception will be thrown. Setting the NSJSONWritingPrettyPrinted option will generate JSON with whitespace designed to make the output more readable. If that option is not set, the most compact possible JSON will be generated. If an error occurs, the error parameter will be set and the return value will be nil. The resulting data is a encoded in UTF-8.
 */

+ (NSData*) dataWithJSONABLEObject:(id<NRMAJSONABLE>)obj options:(NSJSONWritingOptions)opt error:(NSError *__autoreleasing *)error
{
    if (![obj conformsToProtocol:@protocol(NRMAJSONABLE)]) {
        NRLOG_ERROR(@"object passed to NRMAJSON not jsonable.");
        (*error) = [NSError errorWithDomain:@"InvalidFirstParameter" code:-1 userInfo:nil];
        return nil;
    }
    id jsonObj = nil;
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
        #endif
        jsonObj = [obj JSONObject];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        NRLOG_ERROR(@"object passed to NRJSON failed to convert to json.");
        [NRMAExceptionHandler logException:exception
                                   class:NSStringFromClass([obj class])
                                selector:@"JSONObject"];
        if (error != nil) {
            *error = [NSError errorWithDomain:@"Could not convert obj to JSON"
                                           code:-2
                                       userInfo:nil];
        }
        return nil;
    }
#endif
    return [NRMAJSON dataWithJSONObject:jsonObj options:opt error:error];
}
+ (NSData *)dataWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError * __autoreleasing *)error
{
    id clazz = objc_getClass("NSJSONSerialization");
    if (clazz) {
        if (![clazz isValidJSONObject:obj]) {
            if (error != nil) {
                *error = [NSError errorWithDomain:@"json.invalid.object" code:-1 userInfo:nil];
            }
            return nil;
        }
        return [clazz dataWithJSONObject:obj options:opt error:error];
    }
    if (error)
        *error = [NSError errorWithDomain:@"json.not.available" code:-1 userInfo:nil];
    return nil;
}

/* Create a Foundation object from JSON data. Set the NSJSONRMAeadingAllowFragments option if the parser should allow top-level objects that are not an NSArray or NSDictionary. Setting the NSJSONRMAeadingMutableContainers option will make the parser generate mutable NSArrays and NSDictionaries. Setting the NSJSONRMAeadingMutableLeaves option will make the parser generate mutable NSString objects. If an error occurs during the parse, then the error parameter will be set and the result will be nil.
 The data must be in one of the 5 supported encodings listed in the JSON specification: UTF-8, UTF-16LE, UTF-16BE, UTF-32LE, UTF-32BE. The data may or may not have a BOM. The most efficient encoding to use for parsing is UTF-8, so if you have a choice in encoding the data passed to this method, use UTF-8.
 */
+ (id)JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError * __autoreleasing*)error
{
    id clazz = objc_getClass("NSJSONSerialization");
    if (clazz) {
        return [clazz JSONObjectWithData:data options:opt error:error];
    }
    if (error)
        *error = [NSError errorWithDomain:@"json.not.available" code:-1 userInfo:nil];
    return nil;
}

@end
