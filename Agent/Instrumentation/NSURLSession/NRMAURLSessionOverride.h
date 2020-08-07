//
//  NRMAURLSessionDataTaskOverride.h
//  NSURLSessionExperiment
//
//  Created by Bryce Buchanan on 3/14/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

NSURLSession* NRMAOverride__sessionWithConfiguration_delegate_delegateQueue(id self,SEL _cmd,NSURLSessionConfiguration* configuration,id<NSURLSessionDelegate>delegate,NSOperationQueue* queue);

NSURLSessionTask* NRMAOverride__dataTaskWithRequest(id self, SEL _cmd, NSURLRequest* request);
NSURLSessionTask* NRMAOverride__dataTaskWithURL(id self, SEL _cmd, NSURL* url);
NSURLSessionTask* NRMAOverride__dataTaskWithURL_completionHandler(id self, SEL _cmd, NSURL* url, void (^completionHandler)(NSData*,NSURLResponse*,NSError*));
NSURLSessionTask* NRMAOverride__dataTaskWithRequest_completionHandler(id self, SEL _cmd,NSURLRequest* request , void (^completionHandler)(NSData*,NSURLResponse*,NSError*));


NSURLSessionTask* NRMAOverride__uploadTaskWithRequest_fromFile_completionHandler(id self, SEL _cmd, NSURLRequest* request, NSURL* fileURL, void (^completionHandler)(NSData*,NSURLResponse*,NSError*));
NSURLSessionTask* NRMAOverride__uploadTaskWithRequest_fromFile(id self, SEL _cmd,NSURLRequest* request,NSURL* fileURL);
NSURLSessionTask* NRMAOverride__uploadTaskWithRequest_fromData_completionHandler(id self, SEL _cmd, NSURLRequest* request, NSData* bodyData, void (^completionHandler)(NSData*,NSURLResponse*,NSError*));
NSURLSessionTask* NRMAOverride__uploadTaskWithRequest_fromData(id self, SEL _cmd, NSURLRequest* request, NSData* data);
NSURLSessionTask* NRMAOverride__uploadTaskWithStreamedRequest(id self, SEL _cmd, NSURLRequest* request);

@interface NRMAURLSessionOverride : NSObject
+ (void) beginInstrumentation;
+ (void) deinstrument;
@end
