//
//  NRURLSessionTaskOverride.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 3/20/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMAURLSessionTaskOverride.h"
#import "NRTimer.h"
#import "NRMAMethodSwizzling.h"
#import <objc/runtime.h>


#define kNRTimerAssociatedObject @"com.NewRelic.NRSessionTask.Timer"
#define kNRSessionDataAssociatedObject @"com.NewRelic.NRSessionTask.Data"

static IMP NRMAOriginal__resume;
static Class __NRMAConcreteClass;



void NRMA__setTimerForSessionTask(NSURLSessionTask* task, NRTimer* timer);

@implementation NRMAURLSessionTaskOverride


static const NSString* lock = @"com.newrelic.urlsessiontask.instrumentation.lock";
+ (void) instrumentConcreteClass:(Class)clazz
{
    //we can avoid a synchronization block if we check to make sure it's nil first!
    if (clazz && NRMAOriginal__resume == nil) {
        //replace NSURLSessionTask -resume method
        @synchronized(lock) {
            if ([clazz instancesRespondToSelector:@selector(resume)] && NRMAOriginal__resume == nil) {
                
                __NRMAConcreteClass = clazz; //save the class we sizzled so we can de-swizzle
                
                NRMAOriginal__resume =  NRMASwapImplementations(clazz, @selector(resume), (IMP)NRMAOverride__resume);
            }
        }
    }
}


+ (void) deinstrument
{
    if (NRMAOriginal__resume != nil) {
        if (sizeof(__NRMAConcreteClass) == sizeof(Class)) {
            //verify __NRConcreteClass is a Class struct
            Class clazz = __NRMAConcreteClass;
            NRMASwapImplementations(clazz, @selector(resume), (IMP)NRMAOriginal__resume);

            NRMAOriginal__resume = nil;
        }
    }
}

@end

void NRMAOverride__resume(id self, SEL _cmd)
{
    if (((NSURLSessionTask*)self).state == NSURLSessionTaskStateSuspended) {
        //the only state resume will start a task is from Suspended.
        //and since we are only instrumenting NSURLSessionUploadTask and
        //NSURLSessionDataTask we only need to start a new timer on this transision
        //since those two restart if they are suspended.
        NRMA__setTimerForSessionTask(self, [NRTimer new]);
    }
    //call original method
    ((void(*)(id,SEL))NRMAOriginal__resume)(self,_cmd);
}

NRTimer* NRMA__getTimerForSessionTask(NSURLSessionTask* task)
{
    return objc_getAssociatedObject(task, kNRTimerAssociatedObject);
}

void NRMA__setTimerForSessionTask(NSURLSessionTask* task, NRTimer* timer)
{
    objc_AssociationPolicy assocPolicy = OBJC_ASSOCIATION_RETAIN;
    if (timer == nil) {
        assocPolicy = OBJC_ASSOCIATION_ASSIGN;
    }
    objc_setAssociatedObject(task, kNRTimerAssociatedObject, timer, assocPolicy);
}

void NRMA__setDataForSessionTask(NSURLSessionTask* task, NSData* data)
{
    objc_AssociationPolicy assocPolicy = OBJC_ASSOCIATION_RETAIN;
    if (data == nil) {
        assocPolicy = OBJC_ASSOCIATION_ASSIGN;
    }
    objc_setAssociatedObject(task, kNRSessionDataAssociatedObject, data, assocPolicy);
}

NSData* NRMA__getDataForSessionTask(NSURLSessionTask* task)
{
    return objc_getAssociatedObject(task, kNRSessionDataAssociatedObject);
}
