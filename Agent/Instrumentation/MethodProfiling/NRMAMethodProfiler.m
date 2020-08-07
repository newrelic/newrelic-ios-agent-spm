    //
//  NRMAMethodProfiler.m
//  NewRelicAgent
//
//  Created by Jeremy Templier on 5/23/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import <UIKit/UIKit.h>
#import "NRTimer.h"
#import "NRMAMethodProfiler.h"
#import "NRLogger.h"
#import "NRMAMethodSwizzling.h"
#import "NRMATraceController.h"
#import "NRMATrace.h"
#import "NRMAClassNode.h"
#import "NRMAActingClassUtils.h"
#import "NRMAExceptionHandler.h"
#import "NRMAActivityNameGenerator.h"
#import <stdlib.h>
#import "NewRelicAgentInternal.h"
#import "NewRelicCustomInteractionInterface.h"
#import "NRMAClassDataContainer.h"
#import "NRMAFlags.h"

#define NRMAMethodStoragePrefix @"NRMAMethodOverride_"
#define CONFIGURATION_FILE_NAME @"newrelic_profiler"
#define CONFIGURATION_FILE_TYPE @"plist"
#define PROFILER_METRIC_NAME_PREFIX @"Mobile/iOS/Profiler/"

#pragma mark - definitions


static dispatch_once_t skipInstrumentationOnceToken;
    static dispatch_once_t methodReplacementOnceToken;

//swift class with non-objc parent class
const NSString* kSwiftClassPrefix  = @"_T";

//swift class with objc parent class
const NSString* kSwiftObjCClassPrefix = @"OBJC_CLASS_$__T";

//swift class identifier
const NSString* kSwiftClassIdentifier = @".";

const NRMAMethodColor NRMAMethodColorBlack = @"black";
const NRMAMethodColor NRMAMethodColorWhite = @"white";
const NRMAMethodColor NRMAMethodColorUnknown = nil;


BOOL NRMA__isSwiftClass(NRMAClassDataContainer *classData);
NSString* NRMA__getDliName(Class cls);
BOOL NRMA__shouldSkipInstrumentation(NRMAClassDataContainer *classData);
IMP NRMA__beginMethod(id self, SEL selector, NRMAMethodColor targetColor, BOOL* isTargetColor, NRMATrace** createdTracePtr);
void NRMA__endMethod(id self, SEL selector, BOOL isTargetColor, NRMATrace* trace);

//0 param
void NRMA__voidParamHandler(id self, SEL selector, NRMAMethodColor methodColor);
void NRMA__blk_voidParamHandler(id self, SEL selector);
void NRMA__wht_voidParamHandler(id self, SEL selector);

//1 param
void NRMA__boolParamHandler(id self, SEL selector, NRMAMethodColor targetColor, BOOL p1);
void NRMA__blk_boolParamHandler(id self, SEL selector, BOOL p1);
void NRMA__wht_boolParamHandler(id self, SEL selector, BOOL p1);

id NRMA__blk_ptrParamHandler(id self, SEL selector, id p1);
id NRMA__wht_ptrParamHandler(id self, SEL selector, id p1);
id NRMA__ptrParamHandler(id self, SEL selector,NRMAMethodColor targetColor, id p1);

//2 params
id NRMA__blk_ptrFloatParamHandler(id self, SEL selector,id p1, CGFloat p2);
id NRMA__wht_ptrFloatParamHandler(id self, SEL selector,id p1, CGFloat p2);
id NRMA__ptrFloatParamHandler(id self, SEL selector, NRMAMethodColor methodColor,id p1, CGFloat p2);

id NRMA__ptrPtrParamHandler(id self, SEL selector, NRMAMethodColor methodColor, id p1, id p2);
id NRMA__blk_ptrPtrParamHandler(id self, SEL selector, id p1, id p2);
id NRMA__wht_ptrPtrParamHandler(id self, SEL selector, id p1, id p2);

//3 params
id NRMA__ptrIntPtrParamHandler(id self, SEL selector, NRMAMethodColor methodColor, id p1, NSUInteger p2, id p3);
id NRMA__wht_ptrIntPtrParamHandler(id self, SEL selector, id p1, NSUInteger p2, id p3);
id NRMA__blk_ptrIntPtrParamHandler(id self, SEL selector, id p1, NSUInteger p2, id p3);

//4 params
NSInteger NRMA__blk_ptrPtrIntPtrParamHandler(id self, SEL selector, id p1, id p2, NSUInteger p3, id p4);
NSInteger NRMA__wht_ptrPtrIntPtrParamHandler(id self, SEL selector, id p1, id p2, NSUInteger p3, id p4);
NSInteger NRMA__ptrPtrIntPtrParamHandler(id self, SEL selector, NRMAMethodColor methodColor, id p1,id p2, NSUInteger p3, id p4);

NSDictionary* NRMA__generateBlackWhiteDictionary(NRMAClassNode* node, NSArray* methods);
NSMutableDictionary* NRMA__generateSwizzleList(NSMutableDictionary* rootNodes, NSDictionary* methods);
NSMutableDictionary* NRMA__generateClassTrees(NSSet* parents);
void NRMA__processClass(Class cls, NSMutableDictionary *results, NSSet *parents);
void NRMA__generateAndSwizzleMethod(NSString *className, NSString *methodName);

// This is used as a wrapper to call method_invoke when the target method
// has a return type of void. If we don't do this, ARC will try to retain
// the (garbage) return value of method_invoke, because it is declared as
// type 'id'.

static NSMutableDictionary* __startTraceDictionary;
static NSMutableDictionary* __blackWhiteDictionary;
static NSMutableSet* __swiftClasses;
static NSMutableSet* __notSwiftClasses;

#pragma mark -

NRMAMethodColor NRMA__MethodColorOther(NRMAMethodColor color)
{
    if (color == NRMAMethodColorBlack) {
        return NRMAMethodColorWhite;
    } else if (color == NRMAMethodColorWhite) {
        return NRMAMethodColorBlack;
    } else {
        return NRMAMethodColorUnknown;
    }
}

@implementation NRMAMethodProfiler

@synthesize collectedMetrics;
@synthesize methodReplacementTime;


static NRMAMethodProfiler *_sharedInstance;

+ (NSMutableDictionary*) blackWhiteDictionary;
{
    return __blackWhiteDictionary;
}
//
// A singleton
+ (NRMAMethodProfiler *)sharedInstance
{
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _sharedInstance = [[NRMAMethodProfiler alloc] init];
    });

    return _sharedInstance;
}

- (void) dealloc {
    self.collectedMetrics = nil;
    [super dealloc];
}

+ (NSDictionary*) instrumentForTraceList
{
    static NSDictionary* __traceMethodList;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //BEWARE adding to this list. You will need to make sure there is a corresponding C function for the added function's signature. also, there are some special cases for init functions.
        __traceMethodList = [@{@"UIViewController":@[@"viewDidLoad",@"viewWillAppear:",@"viewDidAppear:",@"viewWillDisappear:",@"viewDidDisappear:",@"viewWillLayoutSubviews",@"viewDidLayoutSubviews"],
                               @"UIImage":@[@"imageNamed:",@"imageWithContentsOfFile:",@"imageWithData:",@"imageWithData:scale:",@"initWithContentsOfFile:",@"initWithData:",@"initWithData:scale:"],
                               @"NSJSONSerialization":@[@"JSONObjectWithData:options:error:",@"JSONObjectWithStream:options:error:",@"dataWithJSONObject:options:error:",@"writeJSONObject:toStream:options:error:"],
                               @"NSManagedObjectContext":@[@"executeFetchRequest:error:",@"processPendingChanges"]} retain];
    });

    return __traceMethodList;
}

+ (enum NRTraceType) categoryForSelector:(SEL)selector
{
    static NSMutableDictionary* __categoryMethodDictionary;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __categoryMethodDictionary = [[NSMutableDictionary alloc] init];
        NSDictionary* classMethodDictioanry = [NRMAMethodProfiler instrumentForTraceList];
        for (NSString* objectName in classMethodDictioanry){
            [__categoryMethodDictionary addEntriesFromDictionary:[NRMAMethodProfiler dictionaryWithKeys:[classMethodDictioanry objectForKey:objectName]
                                                                                                value:[NSNumber numberWithInt:[NRMAMethodProfiler traceTypeForClass:objectName]]]];

        }
    });

    return [[__categoryMethodDictionary objectForKey:NSStringFromSelector(selector)] intValue];
}

+ (enum NRTraceType) traceTypeForClass:(NSString*) classNamed {
    if ([classNamed isEqualToString:@"UIViewController"]) {
        return NRTraceTypeViewLoading;
    }

    if ([classNamed isEqualToString:@"UIImage"]) {
        return NRTraceTypeImages;
    }

    if ([classNamed isEqualToString:@"NSJSONSerialization"]) {
        return NRTraceTypeJson;
    }

    if ([classNamed isEqualToString:@"UIView"]) {
        return NRTraceTypeViewLoading;
    }

    if ([classNamed isEqualToString:@"NSManagedObjectContext"]) {
        return NRTraceTypeDatabase;
    }

    return NRTraceTypeNone;
}

+ (NSDictionary*) dictionaryWithKeys:(NSArray*)keys value:(id)value
{

    NSMutableDictionary* dictionary = [[[NSMutableDictionary alloc] initWithCapacity:keys.count]autorelease];
    for (NSString* key in keys) {
        [dictionary setValue:value forKey:key];
    }

    return dictionary;
}

+ (NSSet*) whiteList
{
    static NSSet* __whiteListSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __whiteListSet = [NSSet setWithObjects://@"UIView",
                          @"UIImage",
                          @"UIImageView",
                          @"UITableViewController",
                          @"UITableView",
                          @"UITableViewCell",
                          @"UIButton",
                          @"UIViewController",
                          @"UINavigationController",
                          @"NSJSONSerialization",
                          @"NSManagedObjectContext",
                          nil];

    });
    return __whiteListSet;
}

- (id)init
{
    self = [super init];
    if (self) {
        if (!__startTraceDictionary) {
            __startTraceDictionary = [[NSMutableDictionary dictionary] retain];
        }
        if (!__blackWhiteDictionary) {
            __blackWhiteDictionary = [[NSMutableDictionary dictionary] retain];
        }
        if(!__swiftClasses) {
            __swiftClasses = [[NSMutableSet alloc] init];
        }
        if(!__notSwiftClasses) {
            __notSwiftClasses = [[NSMutableSet alloc] init];
        }
    }

    return self;
}

- (void) startMethodReplacement
{
    dispatch_once(&methodReplacementOnceToken, ^{
        NRTimer *timer = [[NRTimer alloc] init];
        NSMutableDictionary* classTree = NRMA__generateClassTrees([NSSet setWithArray:[[NRMAMethodProfiler instrumentForTraceList] allKeys]]);
        tracingObjects = NRMA__generateSwizzleList(classTree, [NRMAMethodProfiler instrumentForTraceList]);
        self.collectedMetrics = [[[NRMAMetricSet alloc] init] autorelease];
        [self initializeProfilers];
        [timer stopTimer];
        self.methodReplacementTime = (float)[timer timeElapsedInSeconds];
        [timer release];
    });
}


- (void)initializeProfilers
{
    for (NRMAClassDataContainer* classContainer in tracingObjects.allKeys) {
        for (NSString* methodName in [tracingObjects objectForKey:classContainer]) {
            startTrace = NO;
            if ([methodName isEqualToString:@"viewDidLoad"] || [methodName isEqualToString:@"viewWillAppear:"]) {
                startTrace = [NRMAFlags shouldEnableDefaultInteractions];
            }

            if (NRMA__shouldSkipInstrumentation(classContainer)) {
                continue;
            }
            [__startTraceDictionary setObject:[NSNumber numberWithBool:startTrace]
                                       forKey:[NSString stringWithFormat:@"%@",methodName]];

            [self profileMethodNamed:methodName inClassNamed:classContainer.name];
        }
    }
}

- (void)profileMethodNamed:(NSString *)method inClassNamed:(NSString *)className
{
    // swizzle the implementation of the original method with the generated method
    NRMA__generateAndSwizzleMethod(className, method);
}

- (NSString *)metricNameForClassNamed:(NSString *)className andMethodNamed:(NSString *)methodName
{
    return [NSString stringWithFormat:@"%@%@/%@/Time", PROFILER_METRIC_NAME_PREFIX, className, methodName];
}
#ifdef DEBUG
+ (void) resetskipInstrumentationOnceToken {
    skipInstrumentationOnceToken = 0;
    methodReplacementOnceToken = 0;
}
#endif

@end

BOOL NRMA__shouldSkipInstrumentation(NRMAClassDataContainer* classData)
{
    static BOOL shouldEnableSwiftInteractionTracing = NO;

    dispatch_once(&skipInstrumentationOnceToken, ^{
        shouldEnableSwiftInteractionTracing = [NRMAFlags shouldEnableSwiftInteractionTracing];
    });

    if (NRMA__isSwiftClass(classData)) {
        return !shouldEnableSwiftInteractionTracing;
    }

    return NO;
}


BOOL NRMA__isSwiftClass(NRMAClassDataContainer* classData)
{

    // using these sets is faster than checking using dl_info
    if ([__swiftClasses containsObject:classData]) {
        return YES;
    }
    if ([__notSwiftClasses containsObject:classData]) {
        return NO;
    }

    //this is very hokey, but there isn't any other way to identify a swiftClass
    if ([classData.name rangeOfString:(NSString*)kSwiftClassIdentifier].location != NSNotFound) {
            [__swiftClasses addObject:classData];
            return YES;
    }

    NSRange classIdentRange = [classData.name rangeOfString:(NSString*)kSwiftClassPrefix];
    if (classIdentRange.location == 0) {
        [__swiftClasses addObject:classData];
        return YES;
    }

    classIdentRange = [classData.name rangeOfString:(NSString*)kSwiftObjCClassPrefix];
    if (classIdentRange.location == 0) {
        [__swiftClasses addObject:classData];
        return YES;
    }

    [__notSwiftClasses addObject:classData];
    return NO;

}

BOOL NRMA_clsIsValid(Class cls)
{
    //we have to check for SwiftObject because it is the top level of root
    //swift objects. if we call class_getSuperClass('SwiftObject') we get 0x4
    //which isn't a class, but it's not NULL so it breaks everything...
    return (cls!=nil);
}
void NRMA__processClass(Class cls, NSMutableDictionary *results, NSSet *parents)
{
    NSString* className = NSStringFromClass(cls);

    NSMutableArray * classHierarchies = [[[NSMutableArray alloc] init] autorelease];
    [classHierarchies insertObject:className atIndex:0];

    while (NRMA_clsIsValid(cls) && ![parents containsObject:className]) {
        cls = class_getSuperclass(cls);
        className = NSStringFromClass(cls);
        if (className != nil){
            NRMAClassDataContainer* dataContainer = [[[NRMAClassDataContainer alloc] initWithCls:cls className:className] autorelease];
            if (NRMA__shouldSkipInstrumentation(dataContainer)) {
                continue;
            }
            [classHierarchies insertObject:className atIndex:0];
        }
    }

    if (!NRMA_clsIsValid(cls)) {
        return;
    }
    NSString* rootClassName = [classHierarchies objectAtIndex:0];
    NRMAClassNode * node = [results objectForKey:rootClassName];

    if (!node) {
        node = [[[NRMAClassNode alloc] initWithName:rootClassName] autorelease];
        [results setObject:node forKey:rootClassName];
    }

    [classHierarchies removeObjectAtIndex:0];
    for (NSString * className in classHierarchies) {
        //create a node
        NRMAClassNode * subNode = [[[NRMAClassNode alloc] initWithName:className] autorelease];
        NRMAClassNode * childNode = [node.children member:subNode];
        if (childNode) {
            subNode = childNode;
        } else {
            [node.children addObject:subNode];
        }
        node = subNode;
    }
}


NSMutableDictionary* NRMA__generateClassTrees(NSSet* parents)
{
    const char *mainImageName = [[[NSBundle mainBundle] executablePath] fileSystemRepresentation];
    NSMutableDictionary* results = [[[NSMutableDictionary alloc] init] autorelease];

    unsigned int classNameCount = 0;
    const char **classNames = objc_copyClassNamesForImage(mainImageName, &classNameCount);
    for (NSUInteger i = 0; i < classNameCount; i++) {
        Class cls = objc_getClass(classNames[i]);
        NRMA__processClass(cls, results, parents);
    }
    free(classNames);

    for (NSString *className in [NRMAMethodProfiler whiteList]) {
        Class cls = NSClassFromString(className);
        if (cls) {
            NRMA__processClass(cls, results, parents);
        }
    }

    return results;
}

static void NRMA__setMethodColor(NSString* className, NSString* methodName, NRMAMethodColor color)
{
    NSMutableDictionary* methodColors = __blackWhiteDictionary;
    if (![methodColors objectForKey:className]) {
        [methodColors setObject:[NSMutableDictionary dictionary] forKey:className];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-multiple-method-names"
#pragma clang diagnostic ignored "-Wstrict-selector-match"
    [[methodColors objectForKey:className] setObject:color forKey:methodName];
#pragma clang diagnostic pop
}

static NRMAMethodColor NRMA__getMethodColor(NSString* className, NSString* methodName)
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-selector-match"
    return [[__blackWhiteDictionary objectForKey:className] objectForKey:methodName];
#pragma pop
}

static NRMAMethodColor NRMA__getMethodColorSuper(NSString* className, NSString* methodName)
{
    Class cls = NSClassFromString(className);
    while (cls) {
        Class superClass = class_getSuperclass(cls);
        if (superClass) {
            NRMAMethodColor color = NRMA__getMethodColor(NSStringFromClass(superClass), methodName);
            if (color) {
                return color;
            }
        }
        cls = superClass;
    }
    return NRMAMethodColorUnknown;
}

NSMutableDictionary* NRMA__generateSwizzleList(NSMutableDictionary* rootNodes, NSDictionary* methods)
{
    NSMutableDictionary* toSwizzle = [[[NSMutableDictionary alloc] init] autorelease];

    for (NRMAClassNode* node in rootNodes.allValues) {
        NSArray* wantedMethods = [methods objectForKey:node.name];
        if (wantedMethods != nil) {
            for (NSString* method in wantedMethods) {
                NRMA__setMethodColor(node.name, method, NRMAMethodColorBlack);
            }
            NRMAClassDataContainer* dataContainer = [[[NRMAClassDataContainer alloc] initWithCls:objc_getClass(node.name.UTF8String) className:node.name] autorelease];
            [toSwizzle setObject:wantedMethods forKey:dataContainer];

            NSDictionary* objectsToSwizzle = NRMA__generateBlackWhiteDictionary(node, wantedMethods);
            [toSwizzle addEntriesFromDictionary:objectsToSwizzle];
        }
    }

    return toSwizzle;
}

static IMP NRMA__searchMethodListForImplementation(SEL target, Method* methodList, unsigned int size)
{
    Method foundMethod = nil;
    for (unsigned int i = 0; i < size; i++) {
        if (method_getName(methodList[i]) == target) {
            foundMethod = methodList[i];
            break;
        }
    }
    if (foundMethod) {
        return method_getImplementation(foundMethod);
    } else {
        return nil;
    }
}

NSDictionary* NRMA__generateBlackWhiteDictionary(NRMAClassNode* node, NSArray* methods)
{
    NSMutableDictionary* objectsToSwizzle = [[[NSMutableDictionary alloc] init] autorelease];

    for (NRMAClassNode* subNode in node.children.allObjects) {
        unsigned int methodListSize = 0;
        Class cls = NSClassFromString(subNode.name);
        Method* methodList = class_copyMethodList(cls, &methodListSize);
        NRMAClassDataContainer* dataContainer = [[[NRMAClassDataContainer alloc] initWithCls:cls className:subNode.name] autorelease];
        if (NRMA__shouldSkipInstrumentation(dataContainer)) {
            free(methodList);
            continue;
        }
        NSMutableArray* implementedMethods = [NSMutableArray array];
        if (methodList) {
            for (NSString* method in methods) {
                SEL selector = NSSelectorFromString(method);
                IMP methodImp = NRMA__searchMethodListForImplementation(selector, methodList, methodListSize);

                if (methodImp) {
                    [implementedMethods addObject:method];
                    NRMAMethodColor parentMethodColor = NRMA__getMethodColorSuper(subNode.name, method);
                    if (parentMethodColor) {
                        NRMA__setMethodColor(subNode.name, method, NRMA__MethodColorOther(parentMethodColor));
                    } else {
                        NRMA__setMethodColor(subNode.name, method, NRMAMethodColorBlack);
                    }
                }
            }
        }

        if ([implementedMethods count]) {
            [objectsToSwizzle setObject:implementedMethods forKey:dataContainer];
        }

        if (methodList) {
            free(methodList);
        }

        NSDictionary* moreObjects = NRMA__generateBlackWhiteDictionary(subNode,methods);
        [objectsToSwizzle addEntriesFromDictionary:moreObjects];
    }

    return objectsToSwizzle;
}



BOOL NRMA__shouldCancelCurrentTrace(id __unsafe_unretained obj)
{
    BOOL stopCurrentTrace = NO;

    NSArray* cancellationObjects = @[@"UINavigationController",@"UITabBarController"];
    if ([NRMATraceController isTracingActive]) {
        if (![NRMATraceController isInteractionObject:obj]) {
            stopCurrentTrace = YES;
        } else {
            NSArray* components = [[NRMATraceController getCurrentActivityName] componentsSeparatedByString:@"#"];
            if ([components count] > 1) {
                NSString* tracedObject = [components objectAtIndex:0];
                for (NSString* killMeClass in cancellationObjects) {
                    if ([tracedObject isEqualToString:killMeClass]) {
                        stopCurrentTrace = YES;
                        break;
                    }
                }
            }
        }
    }
    return stopCurrentTrace;
}

void NRMA__generateAndSwizzleMethod(NSString *className, NSString *methodName)
{
    NRMAMethodColor color = NRMA__getMethodColor(className, methodName);
    SEL originalSelector = NSSelectorFromString(methodName);
    Class klass = NSClassFromString(className);

    BOOL isInstanceMethod = NO;
    Method m = class_getInstanceMethod(klass, originalSelector);
    if (m) {
        isInstanceMethod = YES;
    }

    if (m == NULL && (m = class_getClassMethod(klass, originalSelector)) == NULL) {
        //aint no method by that name.
        return;
    }

    NSString *swizzle_method_name = [NSString stringWithFormat:@"%@%@",NRMAMethodStoragePrefix, methodName];

    SEL swizzleSelector = NSSelectorFromString(swizzle_method_name);

    IMP methodIMP = nil;
    BOOL isBlack = (color == NRMAMethodColorBlack);
    //the case statement starts at 2 because all methods have two arguements:
    // self and _cmd
    switch (method_getNumberOfArguments(m)-2) {
        case 0: //void
            methodIMP = isBlack?(IMP)NRMA__blk_voidParamHandler:(IMP)NRMA__wht_voidParamHandler;
            break;
        case 1: //single arg
        {
            char* argType = method_copyArgumentType(m, 2);
            if(argType == NULL) return;

            //in arm64 BOOL is actually a C++ bool, in architectures prior
            // it is an unsigned char. ¯\_(ツ)_/¯
            if(strcmp(argType, "c") == 0 || strcmp(argType, "B")==0) {
                methodIMP = isBlack?(IMP)NRMA__blk_boolParamHandler:(IMP)NRMA__wht_boolParamHandler;
            } else if (strcmp(argType, "@")==0){ //check if the arg is an object (type id)
                methodIMP = isBlack?(IMP)NRMA__blk_ptrParamHandler:(IMP)NRMA__wht_ptrParamHandler;
            } else {
                //unrecognized parameter type
                free(argType);
                return;
            }
            free(argType);
        }
            break;
        case 2: //two arg
        {
            //we want to inspect the 4th parameter in the argument list.
            //it is the parameter where they types diverge on the two
            //methods we are swizzling with two arguments.
            char* argType = method_copyArgumentType(m, 3);
            if(argType == NULL) return; //something went wrong.
#if __LP64__
#define FLOAT_ARG_SIGNATURE "d"
#else
#define FLOAT_ARG_SIGNATURE "f"
#endif
            if (strcmp(argType, FLOAT_ARG_SIGNATURE)==0 ) { //is it type float ("double" in ARM64-land)?
                methodIMP = isBlack?(IMP)NRMA__blk_ptrFloatParamHandler:(IMP)NRMA__wht_ptrFloatParamHandler;
            } else if (strcmp(argType, "@") == 0) { // is it an object? (type id)
                methodIMP = isBlack?(IMP)NRMA__blk_ptrPtrParamHandler:(IMP)NRMA__wht_ptrPtrParamHandler;
            } else if (strcmp(argType, "^@") == 0) { // is it a pointer to an object? (type id *)
                methodIMP = isBlack?(IMP)NRMA__blk_ptrPtrParamHandler:(IMP)NRMA__wht_ptrPtrParamHandler;
            } else {
                //unrecognized parameter type
                free(argType);
                return;
            }
            free(argType);
        }
            break;
        case 3:
            methodIMP = isBlack?(IMP)NRMA__blk_ptrIntPtrParamHandler:(IMP)NRMA__wht_ptrIntPtrParamHandler;
            break;
        case 4:
            methodIMP = isBlack?(IMP)NRMA__blk_ptrPtrIntPtrParamHandler:(IMP)NRMA__wht_ptrPtrIntPtrParamHandler;
            break;
        default:
            //error
            return;
            break;
    }




    if (isInstanceMethod) {
        class_addMethod(klass, swizzleSelector,methodIMP, method_getTypeEncoding(m));
        NRMASwapOrReplaceInstanceMethod(klass, originalSelector, swizzleSelector);
    } else {
        //we need to add a method to the meta class to create a static method for this class.
        class_addMethod(object_getClass(klass), swizzleSelector,methodIMP, method_getTypeEncoding(m));
        NRMASwapOrReplaceClassMethod(klass, originalSelector, swizzleSelector);
    }
}


#pragma mark - Method Overrides

#pragma mark - Zero Parameters
void NRMA__blk_voidParamHandler(id self, SEL selector)
{
    NRMA__voidParamHandler(self, selector, NRMAMethodColorBlack);
}

void NRMA__wht_voidParamHandler(id self, SEL selector)
{
    NRMA__voidParamHandler(self, selector, NRMAMethodColorWhite);
}

void NRMA__voidParamHandler(id self, SEL selector, NRMAMethodColor methodColor)
{
    if (self == nil) return;

    BOOL isTargetColor =  NO;

    NRMATrace* trace = nil;

    IMP method = NRMA__beginMethod(self, selector, methodColor, &isTargetColor, &trace);

    ((void(*)(id,SEL))method)(self,selector);

    NRMA__endMethod(self, selector,isTargetColor,trace);
}


//a Pointer
#pragma mark - One Parameter (id)

id NRMA__blk_ptrParamHandler(id self, SEL selector, id p1)
{
    return NRMA__ptrParamHandler(self, selector, NRMAMethodColorBlack, p1);
}

id NRMA__wht_ptrParamHandler(id self, SEL selector, id p1)
{
    return NRMA__ptrParamHandler(self, selector, NRMAMethodColorWhite, p1);
}

id NRMA__ptrParamHandler(id self, SEL selector, NRMAMethodColor methodColor, id p1)
{
    if (self == nil) return nil;

    BOOL isTargetColor = NO;

    NRMATrace* trace = nil;

    NSRange rangeOfInit = [NSStringFromSelector(selector) rangeOfString:@"init"];
    BOOL isInitMethod = rangeOfInit.location == 0;

    IMP method = NRMA__beginMethod(self, selector, methodColor, &isTargetColor, &trace);

    id retval = ((id(*)(id,SEL,id))method)(self, selector, p1);
    if (isInitMethod && retval == nil) {
        //this will prevent a crash in NRMA_endMethod in the case where
        //self is dealloc in the init method, and we try to clear the
        //associated object set on self before we call the original method.
        self = retval;
    }
    NRMA__endMethod(self, selector,isTargetColor,trace);

    return retval;
}


//a Pointer, Float
#pragma mark - Two Parameters  (id, float)

id NRMA__blk_ptrFloatParamHandler(id self, SEL selector, id p1, CGFloat p2)
{
    return NRMA__ptrFloatParamHandler(self, selector, NRMAMethodColorBlack, p1, p2);
}

id NRMA__wht_ptrFloatParamHandler(id self, SEL selector, id p1, CGFloat p2)
{
    return NRMA__ptrFloatParamHandler(self, selector, NRMAMethodColorWhite, p1, p2);
}
id NRMA__ptrFloatParamHandler(id self, SEL selector, NRMAMethodColor methodColor, id p1, CGFloat p2)
{
    if (self == nil) return nil;

    BOOL isTargetColor = NO;

    NRMATrace* trace = nil;

    NSRange rangeOfInit = [NSStringFromSelector(selector) rangeOfString:@"init"];
    BOOL isInitMethod = rangeOfInit.location == 0;

    IMP method = NRMA__beginMethod(self, selector, methodColor, &isTargetColor, &trace);

    id retval = ((id(*)(id,SEL,id,CGFloat))method)(self, selector, p1, p2);

    if (isInitMethod && retval == nil) {
        //this will prevent a crash in NRMA_endMethod in the case where
        //self is dealloc in the init method, and we try to clear the
        //associated object set on self before we call the original method.
        self = retval;
    }

    NRMA__endMethod(self, selector,isTargetColor,trace);

    return retval;
}


//a Pointer, NSUInteger, Pointer
#pragma mark - Three Parameters (id, NSUInteger, id)


id NRMA__blk_ptrIntPtrParamHandler(id self, SEL selector, id p1, NSUInteger p2, id p3)
{
    return NRMA__ptrIntPtrParamHandler(self, selector, NRMAMethodColorBlack, p1, p2, p3);
}

id NRMA__wht_ptrIntPtrParamHandler(id self, SEL selector, id p1, NSUInteger p2, id p3)
{
    return NRMA__ptrIntPtrParamHandler(self, selector, NRMAMethodColorWhite, p1, p2, p3);
}

id NRMA__ptrIntPtrParamHandler(id self, SEL selector, NRMAMethodColor methodColor, id p1, NSUInteger p2, id p3)
{
    if (self == nil) return nil;

    BOOL isTargetColor = NO;

    NRMATrace* trace = nil;

    NSRange rangeOfInit = [NSStringFromSelector(selector) rangeOfString:@"init"];
    BOOL isInitMethod = rangeOfInit.location == 0;

    IMP method = NRMA__beginMethod(self, selector, methodColor, &isTargetColor, &trace);

    id retval = ((id(*)(id,SEL,id,NSUInteger,id))method)(self, selector, p1, p2, p3);

    if (isInitMethod && retval == nil) {
        //this will prevent a crash in NRMA_endMethod in the case where
        //self is dealloc in the init method, and we try to clear the
        //associated object set on self before we call the original method.
        self = retval;
    }

    NRMA__endMethod(self, selector,isTargetColor,trace);

    return retval;
}


//pointer, pointer, NSUInteger, pointer

#pragma mark - Four Parameters (id, id, NSUInteger, id)

NSInteger NRMA__blk_ptrPtrIntPtrParamHandler(id self, SEL selector, id p1, id p2, NSUInteger p3, id p4)
{
    return NRMA__ptrPtrIntPtrParamHandler(self, selector,NRMAMethodColorBlack, p1, p2, p3,p4);
}

NSInteger NRMA__wht_ptrPtrIntPtrParamHandler(id self, SEL selector, id p1, id p2, NSUInteger p3, id p4)
{
    return NRMA__ptrPtrIntPtrParamHandler(self, selector, NRMAMethodColorWhite, p1, p2, p3,p4);
}

NSInteger NRMA__ptrPtrIntPtrParamHandler(id self, SEL selector, NRMAMethodColor methodColor, id p1,id p2, NSUInteger p3, id p4)
{
    if (self == nil) return 0;

    BOOL isTargetColor = NO;

    NRMATrace* trace = nil;

    IMP method = NRMA__beginMethod(self, selector, methodColor, &isTargetColor, &trace);

    NSUInteger retval = ((NSUInteger(*)(id,SEL,id,id,NSUInteger,id))method)(self, selector, p1, p2, p3, p4);

    NRMA__endMethod(self, selector,isTargetColor,trace);

    return retval;
}

//pointer pointer

#pragma mark - Two Parameters (id, id)
id NRMA__blk_ptrPtrParamHandler(id self, SEL selector, id p1, id p2)
{
    return NRMA__ptrPtrParamHandler(self, selector, NRMAMethodColorBlack, p1, p2);
}

id NRMA__wht_ptrPtrParamHandler(id self, SEL selector, id p1, id p2)
{
    return NRMA__ptrPtrParamHandler(self, selector, NRMAMethodColorWhite, p1, p2);
}

id NRMA__ptrPtrParamHandler(id self, SEL selector, NRMAMethodColor methodColor, id p1, id p2)
{
    if (self == nil) return nil;

    BOOL isTargetColor = NO;

    NRMATrace* trace = nil;

    NSRange rangeOfInit = [NSStringFromSelector(selector) rangeOfString:@"init"];
    BOOL isInitMethod = rangeOfInit.location == 0;

    IMP method = NRMA__beginMethod(self, selector, methodColor, &isTargetColor, &trace);

    id retval = ((id(*)(id,SEL,id,id))method)(self, selector, p1, p2);

    if (retval == nil) {
        //this will prevent a crash in NRMA_endMethod in the case where
        //self is dealloc in the init method, and we try to clear the
        //associated object set on self before we call the original method.
        self = retval;
    }

    NRMA__endMethod(self, selector,isTargetColor,trace);

    return retval;
}

//bool

#pragma mark - One Parameter (BOOL)
void NRMA__blk_boolParamHandler(id self, SEL selector, BOOL p1)
{
    NRMA__boolParamHandler(self, selector, NRMAMethodColorBlack, p1);
}

void NRMA__wht_boolParamHandler(id self, SEL selector, BOOL p1)
{
    NRMA__boolParamHandler(self,selector,NRMAMethodColorWhite,p1);
}

void NRMA__boolParamHandler(id self, SEL selector, NRMAMethodColor targetColor, BOOL p1)
{
    if (self == nil) return;

    BOOL isTargetColor = NO;

    NRMATrace* trace = nil;

    IMP method = NRMA__beginMethod(self, selector, targetColor,&isTargetColor, &trace);

    ((void(*)(id,SEL,BOOL))method)(self, selector, p1);

    NRMA__endMethod(self, selector,isTargetColor,trace);
}

#pragma mark - Method Override Helper methods

Method NRMA__getMethod(Class class, SEL selector){
    Method method = class_getInstanceMethod(class, selector);
    if (method == nil) {
        method = class_getClassMethod(class, selector);
    }

    return method;
}

IMP NRMA__beginMethod(id self, SEL selector, NRMAMethodColor targetColor, BOOL* isTargetColor, NRMATrace** createdTracePtr)
{
    NSString* cleanSelector = NSStringFromSelector(selector);

    Class actingClass = NRMA_actingClass(self,cleanSelector);

    NRMAMethodColor methodColor = NRMA__getMethodColor(NSStringFromClass(actingClass), NSStringFromSelector(selector));

    (*isTargetColor) = (methodColor == targetColor);
    SEL originalSelector = NSSelectorFromString([NSString stringWithFormat:@"%@%@",NRMAMethodStoragePrefix,cleanSelector]);
    Method method = nil;
    
    if (!(*isTargetColor)) { //there was a discrepancy in the method color.
                             //this means that we are calling [super _cmd];

        // We know we need to update the acting class to some parent class
        // but the Method returned from the parent class could be implemented
        // in a class even further up the hierarchy, if the Method is unimpelemented
        // in the parent class. We need to verify which class owns the Method
        // by moving up the class hierarchy and finding when the IMP of
        // getMethod(parent_n, selector) changes from getMethod(ParentClass,selector)
        //
        // This prevents pevents a method from being called multiple times if
        // there are multiple classes in the class hierarchy that don't implement
        // the SEL selector

        //We know we must move up the hierarchy at least one level.
        actingClass = class_getSuperclass(actingClass);

        //this will be the method we call. But which class actually owns this method?
        method = NRMA__getMethod(actingClass,originalSelector);

        if (method == nil) {
            //if method is nil, this means we've instrumented a method, but the selector we are getting passed doesn't match the selector when when instrumented this method.
            //this means that we have encounted a 3rd party sdk swizzle conflict and now the app will hang in the while loop below. to prevent this from happening
            //let's throw an exeption instead, so we can immediately identify the issue.
            NRLOG_ERROR(@"Unable to find instrumented method. It's possible another framework has renamed the selector. Throwing Exception...");
            @throw [NSException exceptionWithName:@"NRInvalidArgumentException"
                                           reason:[NSString stringWithFormat:@"New Relic detected an unrecognized selector, '%@', sent to '%@'. It's possible _cmd was renamed by an unsafe method_exchangeImplementations().",cleanSelector,NSStringFromClass(actingClass)]
                                         userInfo:nil];
            }

        while (method == NRMA__getMethod(class_getSuperclass(actingClass), originalSelector)) {
            //if the parentClasses method is the same as parentClass->superclass's method
            //the owner is either parentClass->superclass or some class further up the hirearchy.
            actingClass = class_getSuperclass(actingClass);
        }

        // we've skipped over all the classes that don't implement SEL selector.
        // we can now push the acting class for the current selector;
        NRMA_pushActingClass(self, cleanSelector, actingClass);
    } else { // we've matched the color of the method meaning we
             // aren't in a [super _cmd] call. Get the method for the acting class.
        method = NRMA__getMethod(actingClass, originalSelector);
    }

    // MARK: this is potentially not thread safe, but every method that we currently tag is invoked on the UI thread [JK, 2/21/14]
    if ([[__startTraceDictionary objectForKey:NSStringFromSelector(selector)] boolValue]) {

        if (NRMA__shouldCancelCurrentTrace(self)) {
            //we want to make way for user named traces
            //so we check if we should cancel this trace
            //if it's a boring, default view controller
            //currently tracing.
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
            @try {
               #endif
                [NRMATraceController completeActivityTrace];
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
            } @catch (NSException* exception) {
                [NRMAExceptionHandler logException:exception
                                           class:@"NRMATraceMachine"
                                        selector:@"completeActivityTrace"];
                [NRMATraceController cleanup];
            }
            #endif
        }
        if (![NRMATraceController isTracingActive]) {
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
            @try {
                #endif
                NSString* interactionName = [NRMAActivityNameGenerator generateActivityNameFromClass:[self class] selector:selector];
                if ([self respondsToSelector:@selector(customNewRelicInteractionName)]) {
                    NSString* customInteractionName = [(id<NewRelicCustomInteractionInterface>)self customNewRelicInteractionName];
                    if (customInteractionName.length) {
                        interactionName = customInteractionName;
                    }
                }
                [NRMATraceController startTracingWithName:interactionName
                                     interactionObject:self];
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
            } @catch (NSException* exception) {
                [NRMAExceptionHandler logException:exception
                                           class:@"NRMATraceMachine"
                                        selector:@"startTracingWithName:"];
                [NRMATraceController cleanup];
            }
            #endif
        }
    }


    if ([NRMATraceController isTracingActive]) {
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
        @try {
            #endif
            NRMATrace* trace = [NRMATraceController currentTrace];
            (*createdTracePtr) = [[NRMATraceController enterMethod:selector
                                                   fromObjectNamed:NSStringFromClass(actingClass)
                                                       parentTrace:trace
                                                     traceCategory:[NRMAMethodProfiler categoryForSelector:selector]] retain];
#ifndef  DISABLE_NR_EXCEPTION_WRAPPER
        } @catch (NSException* exception) {
            [NRMAExceptionHandler logException:exception
                                       class:@"NRMATraceMachine"
                                    selector:@"enterMethod:fromObjectNamed:parentTrace:traceCategory:"];
            [NRMATraceController cleanup];   
        }
        #endif
    }

    return method_getImplementation(method);
}

void NRMA__endMethod(id self, SEL selector, BOOL isTargetColor, NRMATrace* trace)
{
    if (!isTargetColor) {
        NSString* cleanSelector = [NSStringFromSelector(selector) stringByReplacingOccurrencesOfString:NRMAMethodStoragePrefix withString:@""];
        NRMA_popActingClass(self,cleanSelector);
    }

    #ifndef  DISABLE_NR_EXCEPTION_WRAPPER
    @try {
    #endif
        if (trace != nil && [NRMATraceController isTracingActive] && trace.traceMachine == [NRMATraceController currentTrace].traceMachine) {
            [NRMATraceController exitMethod];
        }
    #ifndef  DISABLE_NR_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                     class:@"NRMATraceMachine"
                                  selector:@"exitMethod"];
    } @finally {
    #endif
        [trace release];
    #ifndef  DISABLE_NR_EXCEPTION_WRAPPER
    }
    #endif
}

