//
//  NRMAJSON.h
//  NewRelicAgent
//
//  Created by Jonathan Karon on 4/8/13.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol NRMAJSONABLE <NSObject>
@required
/*
 return value must return return true when passed to [NSJSONSerialization isValidJSONObject]
 */
- (id) JSONObject;

@end
@interface NRMAJSON : NSObject

/* Provides an interface to json serizlizer with non-validJSONObjects that impliment -JSONObject which returns a validJSON Object
 */
+ (NSData*) dataWithJSONABLEObject:(id<NRMAJSONABLE>)obj options:(NSJSONWritingOptions)opt error:(NSError *__autoreleasing *)error;

/* Generate JSON data from a Foundation object. If the object will not produce valid JSON then an exception will be thrown. Setting the NSJSONWritingPrettyPrinted option will generate JSON with whitespace designed to make the output more readable. If that option is not set, the most compact possible JSON will be generated. If an error occurs, the error parameter will be set and the return value will be nil. The resulting data is a encoded in UTF-8.
 */
+ (NSData *)dataWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError **)error;

/* Create a Foundation object from JSON data. Set the NSJSONRMAeadingAllowFragments option if the parser should allow top-level objects that are not an NSArray or NSDictionary. Setting the NSJSONRMAeadingMutableContainers option will make the parser generate mutable NSArrays and NSDictionaries. Setting the NSJSONRMAeadingMutableLeaves option will make the parser generate mutable NSString objects. If an error occurs during the parse, then the error parameter will be set and the result will be nil.
 The data must be in one of the 5 supported encodings listed in the JSON specification: UTF-8, UTF-16LE, UTF-16BE, UTF-32LE, UTF-32BE. The data may or may not have a BOM. The most efficient encoding to use for parsing is UTF-8, so if you have a choice in encoding the data passed to this method, use UTF-8.
 */
+ (id)JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError **)error;

@end
