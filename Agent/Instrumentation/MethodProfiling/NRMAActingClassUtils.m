//
//  NSObject+NRMAAssociatedObject.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/29/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAActingClassUtils.h"
#import "NRMAClassDataContainer.h"
#import <objc/runtime.h>
#import <pthread.h>

static const char key;


void NRMA_pushActingClass(id self, NSString* selector, Class cls)
{
    NSMutableArray* actingClassArray =  NRMA_actingClassArray(self,selector);

    @try {
        [actingClassArray  addObject:[[NRMAClassDataContainer alloc] initWithCls:cls className:NSStringFromClass(cls)]];
    }
    @catch (NSException *exception) {
        if (cls == nil) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:@"cannot push nil value"
                                         userInfo:nil];
        } else {
            @throw exception;
        }
    }
}

Class NRMA_popActingClass(id self,NSString* selector)
{
    NSMutableArray* actingClassArray = NRMA_actingClassArray(self,selector);
    Class cls;
    cls = ((NRMAClassDataContainer*)[actingClassArray lastObject]).storedClass;
    if (cls != nil) {
        [actingClassArray removeLastObject];
    }
    return cls;
}

Class NRMA_actingClass(id self,NSString* selector)
{
    Class cls = ((NRMAClassDataContainer*)[NRMA_actingClassArray(self,selector) lastObject]).storedClass;
    if (cls == nil) {
        cls = [self class];
    }
    return cls;
}


static NSString* __NRMAActingClassLock = @"NRMAActingClassLock";
NSMutableArray* NRMA_actingClassArray(id self, NSString* selector)
{
    if (self == nil) {
        return nil;
    }

    NSMutableDictionary*  actingClassThreadsDict = nil;
    @synchronized(__NRMAActingClassLock) {
            actingClassThreadsDict = objc_getAssociatedObject(self, &key);

        if (actingClassThreadsDict == nil) {
            actingClassThreadsDict = [[NSMutableDictionary alloc] init];
            objc_setAssociatedObject(self, &key, actingClassThreadsDict, OBJC_ASSOCIATION_RETAIN);
        }
    }

    NSString* threadId = [NSString stringWithFormat:@"%d",pthread_mach_thread_np(pthread_self())];
    NSMutableDictionary* actingClassStackDict = nil;
    @synchronized(actingClassThreadsDict) {
        actingClassStackDict = [actingClassThreadsDict objectForKey:threadId];

        if (actingClassStackDict == nil) {
            actingClassStackDict = [[NSMutableDictionary alloc] init];
            [actingClassThreadsDict setObject:actingClassStackDict forKey:threadId];
        }

    }
    NSMutableArray* actingClassStack = nil;
    actingClassStack = [actingClassStackDict objectForKey:selector];
    if (!actingClassStack) {
        /*
         * the associatedObject will persist for the lifetime of the object
         * but will be release after the object is dealloced.
         */
        actingClassStack = [[NSMutableArray alloc] init];
        [actingClassStackDict setObject:actingClassStack forKey:selector];
    }
    return actingClassStack;
}

