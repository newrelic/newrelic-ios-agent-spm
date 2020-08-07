//
//  NRMAURLSessionDataTaskOverride.m
//  NSURLSessionExperiment
//
//  Created by Bryce Buchanan on 3/14/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAURLSessionOverride.h"
#import "NRMAMethodSwizzling.h"
#import <objc/runtime.h>
#import "NRMAMethodSwizzling.h"
#import "NRTimer.h"
#import "NRMAMeasurements.h"
#import "NRMAURLSessionTaskOverride.h"
#import "NewRelicInternalUtils.h"
#import "NRMAExceptionHandler.h"
#import "NRMAURLSessionTaskDelegate.h"
#import "NRMANSURLConnectionSupport+private.h"
#import "NRMAHTTPUtilities.h"
#import "NRMAAssociate.h"

#define NRMASwizzledMethodPrefix @"_NRMAOverride__"

IMP NRMAOriginal__sessionWithConfiguration_delegate_delegateQueue;

IMP NRMAOriginal__dataTaskWithRequest;
IMP NRMAOriginal__dataTaskWithRequest_completionHandler;
IMP NRMAOriginal__dataTaskWithURL;
IMP NRMAOriginal__dataTaskWithURL_completionHandler;

IMP NRMAOriginal__uploadTaskWithRequest_fromFile;
IMP NRMAOriginal__uploadTaskWithRequest_fromFile_completionHandler;
IMP NRMAOriginal__uploadTaskWithRequest_fromData;
IMP NRMAOriginal__uploadTaskWithRequest_fromData_completionHandler;
IMP NRMAOriginal__uploadTaskWithStreamedRequest;


void NRMA__recordTask(NSURLSessionTask* task, NSData* data, NSURLResponse* response, NSError* error);
void NRMA__instanceSwizzleIfNotSwizzled(Class clazz, SEL selector, IMP newImplementation);

@interface NRMAIMPContainer : NSObject
@property(readonly) IMP imp;
- (instancetype) initWithImp:(IMP)imp;
@end
@implementation NRMAIMPContainer

- (instancetype) initWithImp:(IMP)imp
{
    self = [super init];
    if (self) {
        _imp = imp;
    }
    return self;
}

@end
@implementation NRMAURLSessionOverride

+ (void) beginInstrumentation
{
    id clazz = objc_getClass("NSURLSession");
    if (clazz) {

        //session task overrides
        NRMAOriginal__sessionWithConfiguration_delegate_delegateQueue = NRMASwapImplementations(clazz,@selector(sessionWithConfiguration:delegate:delegateQueue:), (IMP)NRMAOverride__sessionWithConfiguration_delegate_delegateQueue);

        /*
         * In iOS 13 the definition of NSURLSession changed under the hood, and the way we instrument these methods has changed. iOS 13 specific requirements are wrapped in a @available.
         */
        if (@available(iOS 13, *)) {
            id obj = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
            id concreteClass = [obj class];
            clazz = concreteClass;
        }
        // Data Task  method overrides
        NRMAOriginal__dataTaskWithRequest = NRMASwapImplementations(clazz, @selector(dataTaskWithRequest:), (IMP)NRMAOverride__dataTaskWithRequest);
        
        NRMAOriginal__dataTaskWithURL = NRMASwapImplementations(clazz, @selector(dataTaskWithURL:), (IMP)NRMAOverride__dataTaskWithURL);

        if (@available(iOS 13, *)) { //in os prior to 13 dataTaskWithURL would call dataTaskWithRequest in turn. This is no longer the case, and must be instrumented explicitly.
            NRMAOriginal__dataTaskWithURL_completionHandler = NRMASwapImplementations(clazz, @selector(dataTaskWithURL:completionHandler:), (IMP) NRMAOverride__dataTaskWithURL_completionHandler);
        }
        
        NRMAOriginal__dataTaskWithRequest_completionHandler = NRMASwapImplementations(clazz, @selector(dataTaskWithRequest:completionHandler:), (IMP)NRMAOverride__dataTaskWithRequest_completionHandler);
        
        //upload tasks method overrides
        NRMAOriginal__uploadTaskWithRequest_fromData = NRMASwapImplementations(clazz, @selector(uploadTaskWithRequest:fromData:), (IMP)NRMAOverride__uploadTaskWithRequest_fromData);
        
        NRMAOriginal__uploadTaskWithRequest_fromData_completionHandler = NRMASwapImplementations(clazz, @selector(uploadTaskWithRequest:fromData:completionHandler:), (IMP)NRMAOverride__uploadTaskWithRequest_fromData_completionHandler);

        NRMAOriginal__uploadTaskWithRequest_fromFile_completionHandler = NRMASwapImplementations(clazz, @selector(uploadTaskWithRequest:fromFile:completionHandler:), (IMP)NRMAOverride__uploadTaskWithRequest_fromFile_completionHandler);
        
        NRMAOriginal__uploadTaskWithRequest_fromFile = NRMASwapImplementations(clazz, @selector(uploadTaskWithRequest:fromFile:), (IMP)NRMAOverride__uploadTaskWithRequest_fromFile);
        
        NRMAOriginal__uploadTaskWithStreamedRequest=NRMASwapImplementations(clazz,@selector(uploadTaskWithStreamedRequest:),(IMP)NRMAOverride__uploadTaskWithStreamedRequest);
    }
}

+ (void) deinstrument
{
    id clazz = objc_getClass("NSURLSession");
    if (clazz) {
        //session task overrides
        NRMASwapImplementations(clazz, @selector(sessionWithConfiguration:delegate:delegateQueue:), (IMP)NRMAOriginal__sessionWithConfiguration_delegate_delegateQueue);
        
        id obj = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        id concreteClass = [obj class];
        clazz = concreteClass;
        NRMAOriginal__sessionWithConfiguration_delegate_delegateQueue = nil;
        
        // Data Task  method overrides
        NRMASwapImplementations(clazz,@selector(dataTaskWithRequest:), (IMP)NRMAOriginal__dataTaskWithRequest);
        NRMAOriginal__dataTaskWithRequest = nil;

        if (@available(iOS 13, *)) { // see note in +(void)instrument;
            NRMASwapImplementations(clazz, @selector(dataTaskWithURL:completionHandler:), (IMP)NRMAOriginal__dataTaskWithURL_completionHandler);
            NRMAOriginal__dataTaskWithURL_completionHandler = nil;
        }
        
        NRMASwapImplementations(clazz,@selector(dataTaskWithURL:),(IMP)NRMAOriginal__dataTaskWithURL);
        NRMAOriginal__dataTaskWithURL = nil;
        
        NRMASwapImplementations(clazz,@selector(dataTaskWithRequest:completionHandler:),(IMP)NRMAOriginal__dataTaskWithRequest_completionHandler);
        NRMAOriginal__dataTaskWithRequest_completionHandler = nil;
        
        //upload tasks method overrides
        NRMASwapImplementations(clazz,@selector(uploadTaskWithRequest:fromData:),(IMP)NRMAOriginal__uploadTaskWithRequest_fromData);
        NRMAOriginal__uploadTaskWithRequest_fromData = nil;
        
        NRMASwapImplementations(clazz,@selector(uploadTaskWithRequest:fromData:completionHandler:),(IMP)NRMAOriginal__uploadTaskWithRequest_fromData_completionHandler);
        NRMAOriginal__uploadTaskWithRequest_fromData_completionHandler = nil;
        
        NRMASwapImplementations(clazz,@selector(uploadTaskWithRequest:fromFile:completionHandler:),(IMP)NRMAOriginal__uploadTaskWithRequest_fromFile_completionHandler);
        NRMAOriginal__uploadTaskWithRequest_fromFile_completionHandler= nil;
        
        NRMASwapImplementations(clazz,@selector(uploadTaskWithRequest:fromFile:),(IMP)NRMAOriginal__uploadTaskWithRequest_fromFile);
        NRMAOriginal__uploadTaskWithRequest_fromFile = nil;
        
        NRMASwapImplementations(clazz,@selector(uploadTaskWithStreamedRequest:),(IMP)NRMAOriginal__uploadTaskWithStreamedRequest);
        NRMAOriginal__uploadTaskWithStreamedRequest = nil; 
    }

    [NRMAURLSessionTaskOverride deinstrument];
    
}

@end
//NSURLSession -sessionWithConfiguration:delegate:delegateQueue
NSURLSession* NRMAOverride__sessionWithConfiguration_delegate_delegateQueue(id self,
                                                                          SEL _cmd,
                                                                          NSURLSessionConfiguration* configuration,
                                                                          id<NSURLSessionDelegate> delegate,
                                                                          NSOperationQueue* queue)
{
    NSURLSession* session =  ((id(*)(id, SEL, id, id, id))NRMAOriginal__sessionWithConfiguration_delegate_delegateQueue)(self,
                                                                                         _cmd,
                                                                                         configuration,
                                                                                         delegate?[[NRMAURLSessionTaskDelegate alloc] initWithOriginalDelegate:delegate]:nil,
                                                                                         queue);
    return session;
}


#pragma mark - NSURLSessionDataTask overrides

NSURLSessionTask* NRMAOverride__dataTaskWithRequest(id self, SEL _cmd, NSURLRequest* request)
{
    IMP originalImp = NRMAOriginal__dataTaskWithRequest;

    NSURLSessionTask* task = ((id(*)(id,SEL,NSURLRequest*))originalImp)(self,_cmd,request);
    //try to override the methods of the private class that is returned by this method
    [NRMAURLSessionTaskOverride instrumentConcreteClass:[task class]];
    
    return task;
}

/*
 * This method will not be utilized in os versions less than 13 due to branches in the above -[instrument] method. In 12 and below, -[NSURLSession dataTaskWithURL:completionHandler:] calls through to dataTaskWithRequest.
 */
NSURLSessionTask* NRMAOverride__dataTaskWithURL_completionHandler(id self, SEL _cmd, NSURL* url , void (^completionHandler)(NSData*,NSURLResponse*,NSError*)){
    return NRMAOverride__dataTaskWithRequest_completionHandler(self, _cmd, [NSURLRequest requestWithURL:url], completionHandler);
}


NSURLSessionTask* NRMAOverride__dataTaskWithRequest_completionHandler(id self, SEL _cmd,NSURLRequest* request , void (^completionHandler)(NSData*,NSURLResponse*,NSError*))
{
    IMP originalImp = NRMAOriginal__dataTaskWithRequest_completionHandler;
    NSMutableURLRequest* mutableRequest = [NRMAHTTPUtilities addCrossProcessIdentifier:request];
    NRMAPayloadContainer* payload = [NRMAHTTPUtilities addConnectivityHeader:mutableRequest];

    if (completionHandler == nil) {

        NSURLSessionDataTask* task  = ((id(*)(id,SEL,NSURLRequest*,void(^)(NSData*,NSURLResponse*,NSError*)))originalImp)(self,_cmd,mutableRequest,completionHandler);

        [NRMAHTTPUtilities attachPayload:payload
                                      to:task.originalRequest];

        [NRMAURLSessionTaskOverride instrumentConcreteClass:[task class]];
        return task;
    }
    
    __block NSURLSessionTask* task = nil;

    task =  ((id(*)(id,SEL,NSURLRequest*,void(^)(NSData*,NSURLResponse*,NSError*)))originalImp)(self,_cmd,mutableRequest,^(NSData* data, NSURLResponse* response, NSError* error){

        [NRMAHTTPUtilities attachPayload:payload
                                      to:task.originalRequest];

        NRMA__recordTask(task,data,response,error);

        completionHandler(data,response,error);
    });

    [NRMAURLSessionTaskOverride instrumentConcreteClass:[task class]];
    //try to override the methods of the private class that is returned by this method

    return task;
    
}

NSURLSessionTask* NRMAOverride__dataTaskWithURL(id self, SEL _cmd, NSURL* url)
{
    IMP originalImp = NRMAOriginal__dataTaskWithURL;
    NSURLSessionTask* task = ((id(*)(id,SEL,NSURL*))originalImp)(self,_cmd,url);
    
    //try to override the methods of the private class that is returned by this method
    [NRMAURLSessionTaskOverride instrumentConcreteClass:[task class]];
    return task;
}

#pragma mark - NSURLSessionUploadTask Overrides

NSURLSessionTask* NRMAOverride__uploadTaskWithRequest_fromFile(id self, SEL _cmd, NSURLRequest* request, NSURL* fileURL)
{
    IMP originalImp = (IMP)NRMAOriginal__uploadTaskWithRequest_fromFile;

    NSMutableURLRequest* mutableRequest = [NRMAHTTPUtilities addCrossProcessIdentifier:request];
    NRMAPayloadContainer* payload = [NRMAHTTPUtilities addConnectivityHeader:mutableRequest];
    NSURLSessionTask* task = ((NSURLSessionTask*(*)(id,SEL,NSURLRequest*,NSURL*))originalImp)(self,_cmd,mutableRequest,fileURL);

    [NRMAHTTPUtilities attachPayload:payload
                                  to:task.originalRequest];

    [NRMAURLSessionTaskOverride instrumentConcreteClass:[task class]];
    
    return task;
}
NSURLSessionTask* NRMAOverride__uploadTaskWithRequest_fromData(id self, SEL _cmd, NSURLRequest* request, NSData* data)
{
    IMP originalImp = (IMP)NRMAOriginal__uploadTaskWithRequest_fromData;

    NSMutableURLRequest* mutableRequest = [NRMAHTTPUtilities addCrossProcessIdentifier:request];

    NRMAPayloadContainer* payload = [NRMAHTTPUtilities addConnectivityHeader:mutableRequest];

    NSURLSessionTask* task = ((NSURLSessionTask*(*)(id,SEL,NSURLRequest*,NSData*))originalImp)(self, _cmd, mutableRequest, data);

    [NRMAHTTPUtilities attachPayload:payload to:task.originalRequest];

    [NRMAURLSessionTaskOverride instrumentConcreteClass:[task class]];
    
    return task;
}
NSURLSessionTask* NRMAOverride__uploadTaskWithStreamedRequest(id self, SEL _cmd, NSURLRequest* request)
{
    IMP originalImp = (IMP)NRMAOriginal__uploadTaskWithStreamedRequest;

    NSURLSessionTask* task = ((NSURLSessionTask*(*)(id,SEL,NSURLRequest*))originalImp)(self, _cmd,request);
    
    [NRMAURLSessionTaskOverride instrumentConcreteClass:[task class]];
    
    return task;
}

NSURLSessionUploadTask* NRMAOverride__uploadTaskWithRequest_fromFile_completionHandler(id self, SEL _cmd, NSURLRequest* request, NSURL* fileURL, void (^completionHandler)(NSData*,NSURLResponse*,NSError*))
{
    IMP originalIMP = NRMAOriginal__uploadTaskWithRequest_fromFile_completionHandler;
    NSMutableURLRequest* mutableRequest = [NRMAHTTPUtilities addCrossProcessIdentifier:request];
    NRMAPayloadContainer* payload = [NRMAHTTPUtilities addConnectivityHeader:mutableRequest];

    if (completionHandler == nil) {
        NSURLSessionUploadTask* task = ((NSURLSessionUploadTask*(*)(id,SEL,NSURLRequest*,NSURL*,void(^)(NSData*,NSURLResponse*,NSError*)))originalIMP)(self,_cmd,mutableRequest,fileURL,completionHandler);
        [NRMAURLSessionTaskOverride instrumentConcreteClass:[task class]];
        [NRMAHTTPUtilities attachPayload:payload
                                      to:task.originalRequest];
        return task;
    }
    
    __block NSURLSessionUploadTask* task = nil;
    task =  ((NSURLSessionUploadTask*(*)(id,SEL,NSURLRequest*,NSURL*,void(^)(NSData*,NSURLResponse*,NSError*)))originalIMP)(self,_cmd,mutableRequest,fileURL,^(NSData* data,
                                                                                                                                                        NSURLResponse* response,
                                                                                                                                                        NSError* error){

        [NRMAHTTPUtilities attachPayload:payload
                                      to:task.originalRequest];

        NRMA__recordTask(task,data,response,error);

        completionHandler(data,response,error);
    });
    
    //try to override the methods of the private class that is returned by this method
    [NRMAURLSessionTaskOverride instrumentConcreteClass:[task class]];
    return task;
    
}

//- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler

NSURLSessionUploadTask* NRMAOverride__uploadTaskWithRequest_fromData_completionHandler(id self, SEL _cmd, NSURLRequest* request, NSData* bodyData, void (^completionHandler)(NSData*,NSURLResponse*,NSError*))
{
    IMP originalIMP = NRMAOriginal__uploadTaskWithRequest_fromData_completionHandler;
    NSMutableURLRequest* mutableRequest = [NRMAHTTPUtilities addCrossProcessIdentifier:request];
    NRMAPayloadContainer* payload = [NRMAHTTPUtilities addConnectivityHeader:mutableRequest];
    if (completionHandler == nil) {
        NSURLSessionUploadTask* task = ((NSURLSessionUploadTask*(*)(id,SEL,NSURLRequest*,NSData*,void(^)(NSData*,NSURLResponse*,NSError*)))originalIMP)(self,_cmd,mutableRequest,bodyData,completionHandler);

        [NRMAHTTPUtilities attachPayload:payload
                                      to:task.originalRequest];

        [NRMAURLSessionTaskOverride instrumentConcreteClass:[task class]];
        return task;
    }
    
    __block NSURLSessionUploadTask* task = nil;
    task =  ((NSURLSessionUploadTask*(*)(id,SEL,NSURLRequest*,NSData*,void(^)(NSData*,NSURLResponse*,NSError*)))originalIMP)(self,_cmd,mutableRequest,bodyData,^(NSData* data, NSURLResponse* response, NSError* error){

        [NRMAHTTPUtilities attachPayload:payload
                                      to:task.originalRequest];

        NRMA__recordTask(task,data,response,error);

        completionHandler(data,response,error);
    });
    
    //try to override the methods of the private class that is returned by this method
    [NRMAURLSessionTaskOverride instrumentConcreteClass:[task class]];
    return task;
}


void NRMA__recordTask(NSURLSessionTask* task, NSData* data, NSURLResponse* response, NSError* error)
{
    @try {
        NRTimer* timer = NRMA__getTimerForSessionTask(task);
        if (timer) {//if there is no timer, let's not record this network activity.
            //this could mean a session executed before task was instrumented
            // no biggie
            if (error) {
                //log error
                [NRMANSURLConnectionSupport noticeError:error
                                           forRequest:task.originalRequest
                                            withTimer:timer];
            } else {
                [NRMANSURLConnectionSupport noticeResponse:response
                                              forRequest:task.originalRequest
                                               withTimer:timer
                                                 andBody:data
                                               bytesSent:(NSUInteger)task.countOfBytesSent
                                           bytesReceived:(NSUInteger)task.countOfBytesReceived];
            }
        } else {
            NRLOG_VERBOSE(@"New Relic Timer not set for SessionTask with request url: %@. Not recording transaction.",task.originalRequest.URL);
        }
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                   class:@"NSURLSessionOverride"
                                selector:@"recordTask"];
    }
}
