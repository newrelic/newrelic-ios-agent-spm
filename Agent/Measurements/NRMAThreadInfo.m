//
//  NRMAThreadInfo.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/20/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAThreadInfo.h"
#import <pthread.h>
#import "NewRelicInternalUtils.h"
#import "NRLogger.h"

@implementation NRMAThreadInfo

- (id) init
{
    self = [super init];
    if (self) {
        NSString* threadName = [NSThread currentThread].name;
        
        _identity = pthread_mach_thread_np(pthread_self());
        
        if ([NSThread mainThread] == [NSThread currentThread]) {
            threadName = @"Main Thread";
        }
        
        if (threadName.length == 0 && !(threadName = [NRMAThreadInfo fetchThreadNameForKey:[NSNumber numberWithInteger:_identity]])) {
            threadName = [NSString stringWithFormat:@"Worker Thread #%"NRMA_NSU,[NRMAThreadInfo threadNamesCount]+1];
            [NRMAThreadInfo addThreadName:threadName forKey:[NSNumber numberWithInteger:_identity]];
        }
        
        _name = [threadName length]? [threadName copy] : @"";
    }
    return self;
}


+ (NSMutableDictionary*) threadNames
{

    static NSMutableDictionary* __threadNames;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __threadNames = [[NSMutableDictionary alloc] init];
    });
    
    @synchronized(__threadNames) {
        return __threadNames;
    }
}

+ (NSUInteger) threadNamesCount
{
    NSMutableDictionary* threadNames = [NRMAThreadInfo threadNames];
    @synchronized(threadNames) {
        return [threadNames count];
    }
}
+ (NSString*) fetchThreadNameForKey:(id)key
{
    NSMutableDictionary* threadNames = [NRMAThreadInfo threadNames];
    @synchronized(threadNames) {
        return [threadNames objectForKey:key];
    }
}

+ (void) addThreadName:(NSString*)threadName forKey:(id)key
{
    if (! threadName) {
        NRLOG_ERROR(@"nil thread name passed to addThreadName:forKey:");
        return;
    }
   
    NSMutableDictionary* threadNames = [NRMAThreadInfo threadNames];
    @synchronized(threadNames) {
        [threadNames setObject:threadName forKey:key];
    }
}

+ (void) clearThreadNames
{
    NSMutableDictionary* threadNames = [NRMAThreadInfo threadNames];
    @synchronized(threadNames) {
        [threadNames removeAllObjects];
    }
}

- (void) setThreadName:(NSString *)threadname
{
    @synchronized(_name) {
        _name = [threadname copy];
    }
}
- (BOOL) isEqual:(id)object
{
    if (![object isKindOfClass:[NRMAThreadInfo class]]) {
        return NO;
    }
    NRMAThreadInfo* that = (NRMAThreadInfo*)object;
    return self.identity == that.identity;
}

- (NSUInteger) hash
{
    return self.identity;
}

- (NSString*) toString
{
    return [NSString stringWithFormat:@"TreadInfo{id=%d,name='%@'}",self.identity,self.name];
}
@end
