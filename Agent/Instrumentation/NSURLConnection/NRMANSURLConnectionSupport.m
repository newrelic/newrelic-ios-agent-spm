//
//  NRMANSURLConnectionSupport.m
//  NewRelicAgent
//
//  Created by Jonathan Karon on 10/31/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMANSURLConnectionSupport.h"
#import "NRLogger.h"
#import "NRTimer.h"
#import <objc/runtime.h>
#import <objc/objc.h>
#import "NRMAHTTPUtilities.h"
#import "NRMANSURLConnectionDelegate.h"
#import "NRMANetworkFacade.h"
#import "NRMAPayloadContainer.h"
#import "NRMAHarvestController.h"
// adapted from
// https://bitbucket.org/martijnthe/nsurlconnectionvcr/src/09f7a286eec76a4fa456ed5b92060c48c7d11def/NSURLConnectionVCR/NSURLConnectionVCR.m?at=master
//

static id initWithRequest_delegate(id self, SEL _cmd, NSURLRequest* request, id realdelegate);
static id initWithRequest_delegate_startImmediately(id self, SEL _cmd, NSURLRequest* request, id<NSURLConnectionDelegate> realDelegate, BOOL startImmediately);



id (*NRMA__NSURLConn_initWithRequest_delegate_startImmediately)(id,SEL,NSURLRequest*,id,BOOL);
id (*NRMA__NSURLConn__initWithRequest__delegate)(id, SEL, NSURLRequest*, id);

struct objc_class;
static IMP *origImps = NULL;
static const unsigned char swizzleCount;
static SEL swizzleSelectors[];

#define kNRMANSURLConnectionWrapperKey @"nr_nsurlconn_wrapper_key"





@implementation NRMANSURLConnectionSupport
#pragma mark - test helpers
+ (IMP*) getIMPArray
{
    return origImps;
}
+ (IMP) getNRMA_InitWithReqeust_Delegate_
{
    return (IMP)NRMA__NSURLConn__initWithRequest__delegate;
}
+ (IMP) getNRMA_InitWithRequest_Delegate_StartImmediately
{
    return (IMP)NRMA__NSURLConn_initWithRequest_delegate_startImmediately;
}

+ (void) set__NRMA__initWithRequest_delegate_startImmediately:(IMP)imp
{
    NRMA__NSURLConn_initWithRequest_delegate_startImmediately = (id(*)(id,SEL,NSURLRequest*,id,BOOL))imp;
}

+ (void) set__NRMA__initWithRequest_delegate:(IMP)imp
{
    NRMA__NSURLConn__initWithRequest__delegate = (id(*)(id,SEL,NSURLRequest*,id))imp;
}


#pragma mark -
+ (void) overrideURLConnInitMethods
{
    Class clazz = [NSURLConnection class];
    SEL selector = @selector(initWithRequest:delegate:);
    Method method = class_getInstanceMethod(clazz, selector);
    NRMA__NSURLConn__initWithRequest__delegate = (id(*)(id,SEL,NSURLRequest*,id))class_replaceMethod(clazz,
                                                                                                   selector,
                                                                                                   (IMP)initWithRequest_delegate,
                                                                                                   method_getTypeEncoding(method)); //cheaper than fetching the method



    selector = @selector(initWithRequest:delegate:startImmediately:);
    method = class_getInstanceMethod(clazz, selector);
    NRMA__NSURLConn_initWithRequest_delegate_startImmediately = (id(*)(id,SEL,NSURLRequest*,id,BOOL))class_replaceMethod(clazz,
                                                                                                                       selector,
                                                                                                                       (IMP)initWithRequest_delegate_startImmediately,
                                                                                                                       method_getTypeEncoding(method));

}

+ (void) deinstrumentURLConnInitMethods
{
    Class cls = [NSURLConnection class];
    SEL selector = @selector(initWithRequest:delegate:);
    Method method = class_getInstanceMethod(cls, selector);

    method_setImplementation(method, (IMP)NRMA__NSURLConn__initWithRequest__delegate);

    selector = @selector(initWithRequest:delegate:startImmediately:);
    method = class_getInstanceMethod(cls, selector);
    method_setImplementation(method, (IMP)NRMA__NSURLConn_initWithRequest_delegate_startImmediately);

}

+ (BOOL)instrumentNSURLConnection
{

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NRMANSURLConnectionSupport initialize];
    });

    // Swizzle the class methods we want to intercept (instance methods of the metaClasses):
    Class clazz = objc_getMetaClass("NSURLConnection");
    if (clazz) {
        NRLOG_INFO(@"NSURLConnection is present; setting up instrumentation");

        [NRMANSURLConnectionSupport overrideURLConnInitMethods];

        Method origMethod;
        IMP poseImplementation;
        SEL theSelector;
        origImps = (IMP*)malloc(swizzleCount * sizeof(IMP));

        if (origImps == NULL) {
            NRLOG_ERROR(@"Failed to instrument NSURLSession. Malloc error: %s",strerror(errno));
            [NRMANSURLConnectionSupport deinstrumentURLConnInitMethods];
            return NO;
        }
        for (unsigned char i = 0; i < swizzleCount; ++i) {
            theSelector = swizzleSelectors[i];
            origMethod = class_getClassMethod(clazz, theSelector);
            origImps[i] = method_getImplementation(origMethod);

            poseImplementation = imp_implementationWithBlock([NRMANSURLConnectionSupport poseImplementationBlockForSelector:theSelector]);

            class_replaceMethod(clazz, theSelector, poseImplementation, method_getTypeEncoding(origMethod));
        }
        return YES;
    }
    else {
        NRLOG_VERBOSE(@"NSURLConnection is not present; skipping instrumentation");
        [NRMANSURLConnectionSupport deinstrumentURLConnInitMethods];
        return NO;
    }
}

+ (BOOL)deinstrumentNSURLConnection
{
    Class clazz = objc_getClass("NSURLConnection");
    if (clazz) {
        NRLOG_INFO(@"NSURLConnection is present; removing instrumentation");

        [NRMANSURLConnectionSupport deinstrumentURLConnInitMethods];
        

        Method theMethod;
        SEL theSelector;
        IMP previousImp;


        for (unsigned char i = 0; i < swizzleCount; ++i) {
            if (origImps == NULL) {
                break;
            }
            theSelector = swizzleSelectors[i];
            theMethod = class_getClassMethod(clazz, theSelector);
            previousImp = method_setImplementation(theMethod, origImps[i]);
            imp_removeBlock(previousImp);
            origImps[i] = NULL;
        }
        free(origImps);
        origImps = NULL;



        return YES;
    }
    else {
        NRLOG_VERBOSE(@"NSURLConnection is not present; skipping deinstrumentation");

        return NO;
    }
}

static const unsigned char swizzleCount = 2;
static SEL swizzleSelectors[swizzleCount] = {NULL, NULL};

+ (void)initialize {
    swizzleSelectors[0] = @selector(sendSynchronousRequest:returningResponse:error:);
    swizzleSelectors[1] = @selector(sendAsynchronousRequest:queue:completionHandler:);
}


+ (id) poseImplementationBlockForSelector:(SEL)sel
{
    if (sel == @selector(sendSynchronousRequest:returningResponse:error:)) {
        return (id)[[^(id _self, NSURLRequest* request, NSURLResponse *__autoreleasing *response, NSError *__autoreleasing *error) {
            __autoreleasing NSURLResponse *theResponse = nil;
            __autoreleasing NSError *theError = nil;

            NSMutableURLRequest* mutableRequest = [NRMAHTTPUtilities addCrossProcessIdentifier:request];
            mutableRequest = [NRMAHTTPUtilities addConnectivityHeaderAndPayload:mutableRequest];
            NRTimer *timer = [[[NRTimer alloc] init] autorelease];
            NSData *theResponseBody = ((NSData*(*)(id,SEL,NSURLRequest*, NSURLResponse**, NSError**))(origImps[0]))(_self, sel, mutableRequest, &theResponse, &theError);
            [timer stopTimer];

            if (theError) {
                if (error) {
                    *error = theError;
                }
                [NRMANSURLConnectionSupport noticeError:theError
                                           forRequest:mutableRequest
                                            withTimer:timer];
            }
            else {
                NSInteger responseBodyLimit = (NSInteger)[NRMAHarvestController configuration].response_body_limit;
                NSData *capturedData = nil;
                if (theResponseBody.length > 0) {
                    if (theResponseBody.length <= responseBodyLimit) {
                        capturedData = theResponseBody;
                    }
                    else {
                        capturedData = [theResponseBody subdataWithRange:NSMakeRange(0, responseBodyLimit)];
                    }
                }

                [NRMANSURLConnectionSupport noticeResponse:theResponse
                                              forRequest:mutableRequest
                                               withTimer:timer
                                                 andBody:capturedData
                                               bytesSent:0
                                           bytesReceived:theResponseBody.length];
            }
            if (response) {
                *response = theResponse;
            }
            return theResponseBody;
        }copy] autorelease];;
    } else if (sel == @selector(sendAsynchronousRequest:queue:completionHandler:)) {
        return (id)[[^(id _self, NSURLRequest *request, NSOperationQueue *queue, void (^handler)(NSURLResponse*, NSData*, NSError*) )
        {

            NSMutableURLRequest* mutableRequest = [NRMAHTTPUtilities addCrossProcessIdentifier:request];
            mutableRequest = [NRMAHTTPUtilities addConnectivityHeaderAndPayload:mutableRequest];
            NRTimer *timer = [[[NRTimer alloc] init] autorelease];
            ((void(*)(id,SEL,NSURLRequest*,NSOperationQueue*,void(^)(NSURLResponse*,NSData*,NSError*)))origImps[1])(_self, sel, mutableRequest, queue, ^(NSURLResponse *response, NSData *responseBody, NSError *error){
                [timer stopTimer];
                if (error) {
                    [NRMANSURLConnectionSupport noticeError:error
                                               forRequest:mutableRequest
                                                withTimer:timer];
                }
                else {
                    NSInteger responseBodyLimit = (NSInteger) [NRMAHarvestController configuration].response_body_limit;

                    NSData *capturedData = nil;
                    if (responseBody.length > 0) {
                        if (responseBody.length <= responseBodyLimit) {
                            capturedData = responseBody;
                        }
                        else {
                            capturedData = [responseBody subdataWithRange:NSMakeRange(0, responseBodyLimit)];
                        }
                    }

                    [NRMANSURLConnectionSupport noticeResponse:response
                                                  forRequest:mutableRequest
                                                   withTimer:timer
                                                     andBody:capturedData
                                                   bytesSent:0
                                               bytesReceived:responseBody.length];
                }
                if (handler != nil) {
                    handler(response, responseBody, error);
                }
            });
        }copy] autorelease];
    } else {
        return nil;
    }
}


/*
 Returns true if this is a request to the New Relic service.
 */
+ (BOOL)isNewRelicServiceRequest:(NSURLRequest *)request
{
    return [request valueForHTTPHeaderField:X_APP_LICENSE_KEY_REQUEST_HEADER] != nil;
}

#pragma mark

+ (void)noticeError:(NSError*)error forRequest:(NSURLRequest *)request withTimer:(NRTimer *)timer
{
    // ignore self-instrumentation here, the agent records this stuff into Supportability metrics elsewhere
    if ([NRMANSURLConnectionSupport isNewRelicServiceRequest:request]) {
        return;
    }

    // http://developer.apple.com/library/ios/#documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Constants/Reference/reference.html#//apple_ref/doc/uid/TP40003793-CH3g-SW40

    NRLOG_VERBOSE(@"%@\n\tDelay:   %.5lf\n\tError:   %lu\n\t%@",
                  request.URL.description,
                  timer.timeElapsedInSeconds,
                  (unsigned long)error.code,
                  error.description);


    [NRMANetworkFacade noticeNetworkFailure:request
                                  withTimer:timer
                                  withError:error];
}

/*
 Report a network request to the agent.
 */
+ (void)noticeResponse:(NSURLResponse *)response
            forRequest:(NSURLRequest *)request
             withTimer:(NRTimer *)timer
               andBody:(NSData *)body
             bytesSent:(NSUInteger)sent
         bytesReceived:(NSUInteger)received
{
    // ignore self-instrumentation here, the agent records this stuff into Supportability metrics elsewhere
    if ([NRMANSURLConnectionSupport isNewRelicServiceRequest:request]) {
        return;
    }

    [NRMANetworkFacade noticeNetworkRequest:request
                                   response:response
                                  withTimer:timer
                                  bytesSent:sent
                              bytesReceived:received
                               responseData:body
                                     params:nil];
}

+ (NRMANSURLConnectionDelegate*) generateProxyFromDelegate:(id<NSURLConnectionDelegate>)realDelegate
                                                     request:(NSMutableURLRequest*)mutableRequest
                                            startImmediately:(BOOL)startImmediately
{
    NRMANSURLConnectionDelegate* proxyDelegate = [[[NRMANSURLConnectionDelegate alloc] init] autorelease];
    proxyDelegate.realDelegate = realDelegate;
    proxyDelegate.request = mutableRequest;
    if (startImmediately) {
        [proxyDelegate startDownloadTimer];
    }

    return proxyDelegate;
}

@end


static id initWithRequest_delegate_startImmediately(id self, SEL _cmd, NSURLRequest* request, id<NSURLConnectionDelegate> realDelegate, BOOL startImmediately)
{
    if ([request valueForHTTPHeaderField:NEW_RELIC_CROSS_PROCESS_ID_HEADER_KEY] != nil) {
        //avoid double instrumenting the request.
        return NRMA__NSURLConn_initWithRequest_delegate_startImmediately(self,
                                                                         _cmd,
                                                                         request,
                                                                         realDelegate,
                                                                         startImmediately);
    }

    NSMutableURLRequest* mutableRequest = [NRMAHTTPUtilities addCrossProcessIdentifier:request];
    mutableRequest = [NRMAHTTPUtilities addConnectivityHeaderAndPayload:mutableRequest];

    NRMANSURLConnectionDelegate* proxyDelegate = [NRMANSURLConnectionSupport generateProxyFromDelegate:realDelegate
                                                                                               request:mutableRequest
                                                                                      startImmediately:startImmediately];

    NRLOG_VERBOSE(@"%p (proxy %p) initWithRequest:%@", self, proxyDelegate, request.URL.absoluteString);

    return NRMA__NSURLConn_initWithRequest_delegate_startImmediately(self,_cmd, mutableRequest,proxyDelegate,startImmediately);
}


static id initWithRequest_delegate(id self, SEL _cmd, NSURLRequest* request, id realDelegate) {
    return initWithRequest_delegate_startImmediately(self, _cmd, request, realDelegate, YES);
}
