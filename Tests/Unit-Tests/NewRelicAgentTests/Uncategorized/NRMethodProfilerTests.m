
//
//  NRMAMethodProfilerTests.m
//  NewRelicAgent
//
//  Created by Jeremy Templier on 5/23/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#import "NRMethodProfilerTests.h"
#import "NRMAClassNode.h"
#import "NRMAMeasurements.h"
#import "NRMAFlags.h"
#import "NRMATrace.h"
#import "NRMATraceController.h"
#import "NRMAClassDataContainer.h"
#import "NewRelicAgentInternal.h"
#ifdef NRNonJenkinsTests
#import "NewRelicNonJenkinsTests-Swift.h"
#endif
//#ifdef NRTests
//    #if TARGET_OS_TV
//        #import "NewRelicAgentTVOSTests-Swift.h"
//    #else
//        #import "NewRelicAgentTests-Swift.h"
//    #endif
//#endif
#import "NRMAMethodProfiler.h"
@interface NRMATraceController ()
+ (void) exitMethod;
@end


extern BOOL NRMA__isSwiftClass(NRMAClassDataContainer* classData);
NSString* NRMA__getDliName(Class cls);
id NRMA__blk_ptrParamHandler(id self, SEL selector, id p1);







@interface NRMAImage : UIImage
@end

@implementation NRMAImage

+ (id) imageWithData:(NSData*)data
{
    return [UIImage imageWithData:data];
}
@end


@implementation SuperSwizzle
- (id)init
{
    self = [super init];
    if (self) {
        self.calls = [NSMutableArray array];
    }
    return self;
}

- (void)swizzleMe:(BOOL)text
{
}

- (void)recordCall:(NSString*)className withMethodName:(NSString*)methodName andLabel:(NSString*)label
{
    [self.calls addObject:[NSString stringWithFormat:@"[%@ %@] %@", className, methodName, label]];
}

@end


@implementation  SwizzleParent

- (void)swizzleMe:(BOOL)text
{
    [super swizzleMe:text];
//    NSLog(@"World %d",text);
}

- (void)callMe:(NSString*)label
{
    [self recordCall:@"SwizzleParent" withMethodName:@"callMe:" andLabel:label];
}

- (void)callMe:(NSString*)label withBlock:(void (^)(void))block
{
    [self recordCall:@"SwizzleParent" withMethodName:@"callMe:withBlock:" andLabel:label];
    block();
}

@end


@implementation SwizzleChild
- (void)callMe:(NSString*)label
{
    [self recordCall:@"SwizzleChild" withMethodName:@"callMe:" andLabel:label];
    [super callMe:label];
}

- (void)callMe:(NSString*)label withBlock:(void (^)(void))block
{
    [self recordCall:@"SwizzleChild" withMethodName:@"callMe:withBlock:" andLabel:label];
    [super callMe:label withBlock:block];
}
@end

@implementation NRMASubChild


- (void) swizzleMe:(BOOL)text {
    [super swizzleMe:text];
}

- (void)callMe:(NSString*)label
{
    [self recordCall:@"NRMASubChild" withMethodName:@"callMe:" andLabel:label];
    [super callMe:label];
}

- (void)callMe:(NSString*)label withBlock:(void (^)(void))block
{
    [self recordCall:@"NRMASubChild" withMethodName:@"callMe:withBlock:" andLabel:label];
    [super callMe:label withBlock:block];
}

@end

@interface DummyController : UICollectionViewController
@end

@implementation DummyController

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

@end

@interface DummyControllerChild : DummyController
@end

@implementation DummyControllerChild : DummyController
@end

@interface DummyControllerSubChild : DummyControllerChild
@end

@implementation DummyControllerSubChild

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

@end

//NRMAMethodProfiler methods
NSDictionary* ClassesGetSubclasses(NSSet* parents);
NSMutableDictionary* NRMA__generateClassTrees(NSSet* parents);
NSMutableDictionary* NRMA__generateSwizzleList(NSMutableDictionary* rootNodes, NSDictionary* methods);

void NRMA__generateAndSwizzleMethod(NSString* className,NSString* methodName);

@interface NRMAMethodProfiler ()
+ (NSMutableDictionary*)blackWhiteDictionary;
@end
@implementation NRMAMethodProfiler (test)

+ (NSSet*) whiteList
{
    static NSSet* __whiteListSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __whiteListSet = [NSSet setWithObjects:
                          @"SwizzleChild",
                          @"NewRelicAgentTests.NRMA__asdfasdf",
                          @"NewRelicAgentTVOSTests.NRMA__asdfasdf",
                          @"SwizzleParent",
                          @"SuperSwizzle",
                          @"NRMASubChild",
                          @"UIViewController",
                          @"DummyController",
                          @"DummyControllerChild",
                          @"DummyControllerSubChild",
                          @"NRMAImage",
                          nil];
        
    });
    return __whiteListSet;
}

+ (NSDictionary*) instrumentForTraceList
{
    static NSDictionary* __traceMethodList;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __traceMethodList = @{
                              @"SwizzleParent":@[@"swizzleMe:", @"callMe:", @"callMe:withBlock:"],
                              @"UIViewController":@[@"viewWillAppear:"],
                              @"UIImage":@[@"imageWithData:"]
                            };
    });
    
    return __traceMethodList;
}
@end

@implementation NRMAMethodProfilerTests

- (void) setUp
{
//    [[[NRMAMethodProfiler alloc] init] startMethodReplacement];
    //this needs to be initialized because one of the tests will trigger
    //an initialization, and we will need to shut it down.

    NSMutableSet* set = [[NSMutableSet alloc] init];
    [set addObject:[self class]];
    [NRMAMeasurements initializeMeasurements];
    [super setUp];
}

- (void) tearDown
{
    [NRMAMeasurements shutdown];
#ifdef DEBUG
    [NRMAMethodProfiler resetskipInstrumentationOnceToken];
#endif
    [super tearDown];

}
- (dispatch_queue_t) randomQueue
{
    int whichQueue = rand() % 2u;
    switch(whichQueue) {
            //        case 0:
            //            dispatchA++;
            //            dispatch_queue_t queueA = dispatch_get_main_queue();
            //            return queueA;
        case 0:
            return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        case 1:
            return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        case 3:
            //            dispatchD++;
            //            dispatch_queue_t queueD =dispatch_get_current_queue();
            //            return queueD;
        default:
            XCTFail(@"shouldn't have fallen through randomQueue finder");
            return dispatch_get_main_queue();
    }
}

- (void) testManyAsync
{
    int iterations = 1000;
    __block int completed = 0;
    for (int i = 0 ; i < iterations; i++) {

        dispatch_async([self randomQueue], ^{
            NRMASubChild* achild = [[NRMASubChild alloc] init];
            [achild callMe:[NSString stringWithFormat:@"A-%d",i]];
//            NSLog(@"A-%d: %@",i,achild.calls);
            @synchronized([self class]) {
                completed++;
            }
            XCTAssertTrue([achild.calls count] == 3,@"there should be 3 levels of methods");
        });
        dispatch_async([self randomQueue],^{
            NRMASubChild* achild = [[NRMASubChild alloc] init];
            [achild callMe:[NSString stringWithFormat:@"B-%d",i]];
//            NSLog(@"B-%d: %@",i,achild.calls);
            @synchronized([self class]) {
                completed++;
            }
            XCTAssertTrue([achild.calls count] == 3,@"there should be 3 levels of methods");
        });
    }

    while (CFRunLoopGetCurrent() && completed < iterations*2) {
    }
}

- (void) testManyAsyncOnSameObject
{
    int iterations = 1000;
    __block int completed = 0;
    for (int i = 0 ; i < iterations; i++) {
        __block NRMASubChild* achild = [[NRMASubChild alloc] init];
        dispatch_async([self randomQueue], ^{
            [achild callMe:[NSString stringWithFormat:@"A-%d",i]];
//            NSLog(@"A-%d: %@",i,achild.calls);
            @synchronized([self class]) {
                completed++;
            }
            XCTAssertTrue([achild.calls count] == 3,@"there should be 3 levels of methods");
        });
        dispatch_async([self randomQueue],^{
            [achild swizzleMe:YES];
//            NSLog(@"B-%d: %@",i,achild.calls);
            @synchronized([self class]) {
                completed++;
            }
        });
    }

    while (CFRunLoopGetCurrent() && completed < iterations*2) {
    }
}

- (void) testStaticMethodReplacement
{

    NRMAMethodProfiler* methodProfiler = [[NRMAMethodProfiler alloc] init];
    [methodProfiler startMethodReplacement];
    
    // id blk_ptrParamHandler(id self, SEL selector, id p1);
    Method method = class_getClassMethod([UIImage class], @selector(imageWithData:));
    IMP imp = method_getImplementation(method);
//(void*(*)(id,SEL,va_list))
    XCTAssertTrue((id(*)(id,SEL,id))imp == NRMA__blk_ptrParamHandler, @"we swizzled this method ");

    method = class_getClassMethod([UIImage class], @selector(imageNamed:));
    imp = method_getImplementation(method);
    XCTAssertTrue((id(*)(id,SEL,id))imp != NRMA__blk_ptrParamHandler, @"not swizzled!");
}

- (void) testNilReturnCrash
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertNoThrow([NRMAImage imageWithData:nil],@"test no crash on returning a nil value from a swizzled method");
#pragma clang diagnostic pop
}

- (void) assertCallSequence:(NSArray*)expectedCalls forTarget:(id)target
{
    NSArray* calls = [target calls];
    XCTAssertEqual([calls count], [expectedCalls count], @"Expected call count did not match actual call count");
    for (int i = 0; i < [calls count]; i++) {
        NSString* actualCall = [calls objectAtIndex:i];
        NSString* expectedCall = [expectedCalls objectAtIndex:i];
        XCTAssertEqualObjects(actualCall, expectedCall, @"Unexpected call at index %d", i);
    }
}

- (void) testCallingSuperFromInstrumentedMethod
{
    SwizzleParent* s = [[SwizzleChild alloc] init];
    [s callMe:@"foo"];

    NSArray* expected = @[@"[SwizzleChild callMe:] foo", @"[SwizzleParent callMe:] foo"];
    [self assertCallSequence:expected forTarget:s];
}

- (void)testCallingSuperFromInstrumentedMethodTwice
{
    SwizzleParent* s = [[NRMASubChild alloc] init];
    [s callMe:@"foo"];
    [s callMe:@"foo"];

    NSArray* expected = @[@"[NRMASubChild callMe:] foo",
                          @"[SwizzleChild callMe:] foo",
                          @"[SwizzleParent callMe:] foo",
                          @"[NRMASubChild callMe:] foo",
                          @"[SwizzleChild callMe:] foo",
                          @"[SwizzleParent callMe:] foo"];
    [self assertCallSequence:expected forTarget:s];
}

- (void) testCallingSecondInstrumentedMethodFromSuperclassImplementationOfAnother
{
    NRMASubChild* s = [[NRMASubChild alloc] init];
    [s callMe:@"foo" withBlock:^{ [s callMe:@"bar"]; }];

    NSArray* expected = @[@"[NRMASubChild callMe:withBlock:] foo",
                          @"[SwizzleChild callMe:withBlock:] foo",
                          @"[SwizzleParent callMe:withBlock:] foo",
                          @"[NRMASubChild callMe:] bar",
                          @"[SwizzleChild callMe:] bar",
                          @"[SwizzleParent callMe:] bar"];
    [self assertCallSequence:expected forTarget:s];
}

- (void) testCallingSuperSkippingOneLevel
{
    DummyControllerSubChild* c = [[DummyControllerSubChild alloc] initWithCollectionViewLayout:[[UICollectionViewLayout alloc] init]];
    [c viewWillAppear:NO];
}

- (void) testClassGetSubclasses
{
    NSSet* classes = [NSSet setWithObjects:NSStringFromClass([SuperSwizzle class]), nil];
    NSMutableDictionary* subClasses = NRMA__generateClassTrees(classes);
    
    NSArray* expectedHierarchy = @[@"SuperSwizzle",@"SwizzleParent",@"SwizzleChild",@"NRMASubChild"];
    NSMutableArray* recordedHierarchy = [[NSMutableArray alloc] init];
    
    NRMAClassNode* rootNode = [subClasses objectForKey:@"SuperSwizzle"];
    
    NRMAClassNode* classNode = rootNode;
    while ([classNode.children count]) {
        XCTAssertEqual(classNode.children.count, (NSUInteger)1, @"there should only be one object in each child set");
        classNode = classNode.children.anyObject;
    }

    classNode = rootNode;
    do{
        [recordedHierarchy addObject:classNode.name];
        classNode = [classNode.children anyObject];
    }while (classNode);
    
    for (int i = 0; i < [expectedHierarchy count]; i++) {
        XCTAssertEqualObjects([recordedHierarchy objectAtIndex:i], [expectedHierarchy objectAtIndex:i], @"expected specific class hirearchy");
    }
}


- (void) testSwizzleList
{

    //initializes the blackwhitedictionary
    NRMAMethodProfiler* methodProfiler = [[NRMAMethodProfiler alloc] init];
    
    NSSet* rootClassSet = [NSSet setWithObjects:NSStringFromClass([SuperSwizzle class]), nil];
    NSMutableDictionary* classTrees = NRMA__generateClassTrees(rootClassSet);
    NSDictionary* methods = @{@"SuperSwizzle":@[@"swizzleMe:"]};
    
    NSMutableDictionary* swizzleList = NRMA__generateSwizzleList(classTrees,methods);

    NRMAClassDataContainer* container = [[NRMAClassDataContainer alloc] initWithCls:[SwizzleChild class]  className:NSStringFromClass([SwizzleChild class])];
    XCTAssertEqual([swizzleList count],(NSUInteger)3, @"only three objects should be swizzled");
    XCTAssertTrue([swizzleList objectForKey:container] == Nil, @"swizzlechild shouldn't be in this this, because it doesn't implement the swizzleMe method");

    methodProfiler = nil;
}


- (void) testBlackWhiteDictionaryGeneration
{
    //initializes the blackwhitedictionary
    NRMAMethodProfiler* methodProfiler = [[NRMAMethodProfiler alloc] init];

    
    NSSet* rootClassSet = [NSSet setWithObjects:NSStringFromClass([SuperSwizzle class]), nil];
    NSMutableDictionary* classTrees = NRMA__generateClassTrees(rootClassSet);
    NSDictionary* methods = @{@"SuperSwizzle":@[@"swizzleMe:"]};
    
    NRMA__generateSwizzleList(classTrees,methods);

    NSMutableDictionary*blackwhiteDictionary = [NRMAMethodProfiler blackWhiteDictionary];
    XCTAssertEqual([[blackwhiteDictionary objectForKey:@"SwizzleParent"] objectForKey:@"swizzleMe:"], NRMAMethodColorWhite, @"this object should be colored white");
    XCTAssertEqual([[blackwhiteDictionary objectForKey:@"SuperSwizzle"] objectForKey:@"swizzleMe:"], NRMAMethodColorBlack, @"this object should be colored black");
    methodProfiler = nil;
}

- (void) testCallOrder
{
    NRMAMethodProfiler* methodProfiler = [[NRMAMethodProfiler alloc] init];
    [methodProfiler startMethodReplacement];
    
    NRMASubChild* subChild = [[NRMASubChild alloc] init];
    [subChild swizzleMe:YES];
}

IMP NRMA__beginMethod(id self, SEL selector, NRMAMethodColor targetColor, BOOL* isTargetColor, NRMATrace** createdTracePtr);
void NRMA__endMethod(id self, SEL selector, BOOL isTargetColor, NRMATrace* trace);
- (void) testMethodProfilerStartEndInTransTraceMachine
{
    [NRMATraceController completeActivityTrace];
    //Regression test for MOBILE-890
    BOOL targetColor;
    NRMATrace* trace;

    SwizzleChild* controller = [[SwizzleChild alloc] init];

    NRMAMethodProfiler* methodProfiler = [[NRMAMethodProfiler alloc] init];
    [methodProfiler startMethodReplacement];



    IMP imp = NRMA__beginMethod(controller, @selector(swizzleMe:), NRMAMethodColorBlack, &targetColor, &trace);

    XCTAssertTrue(imp, @"should exist");

    XCTAssertNil(trace, @"no interaction is running, no trace should be made");

    NRMA__endMethod(controller, @selector(swizzleMe:), targetColor, trace);


    [NRMATraceController startTracing:YES];

    imp = NRMA__beginMethod(controller, @selector(swizzleMe:), NRMAMethodColorBlack, &targetColor, &trace);

    XCTAssertNotNil(trace, @"trace should have been started for swizzleMe:");

    [NRMATraceController completeActivityTrace];

    [NRMATraceController startTracing:YES];

    id mockMachine = [OCMockObject niceMockForClass:[NRMATraceController class]];
    [[[mockMachine expect] classMethod] exitMethod];

    NRMA__endMethod(controller, @selector(swizzleMe:), targetColor, trace);

    XCTAssertThrows([mockMachine verify], @"NRMA__endMethod shouldn't call [NRMATraceController exitMethod] because the trace's machine doesn't match the current one.");

    [mockMachine stopMocking];
    [NRMATraceController completeActivityTrace];

}



- (void) testProfilerStartButEndAfterTrace
{

    //Regression test for MOBILE-890
    BOOL targetColor;
    NRMATrace* trace;

    SwizzleChild* controller = [[SwizzleChild alloc] init];

    NRMAMethodProfiler* methodProfiler = [[NRMAMethodProfiler alloc] init];
    [methodProfiler startMethodReplacement];



    IMP imp = NRMA__beginMethod(controller, @selector(swizzleMe:), NRMAMethodColorBlack, &targetColor, &trace);

    XCTAssertTrue(imp, @"should exist");

    XCTAssertNil(trace, @"no interaction is running, no trace should be made");

    NRMA__endMethod(controller, @selector(swizzleMe:), targetColor, trace);


    [NRMATraceController startTracing:YES];

    imp = NRMA__beginMethod(controller, @selector(swizzleMe:), NRMAMethodColorBlack, &targetColor, &trace);

    XCTAssertNotNil(trace, @"trace should have been started for swizzleMe:");

    [NRMATraceController completeActivityTrace];

    id mockMachine = [OCMockObject niceMockForClass:[NRMATraceController class]];
    [[[mockMachine expect] classMethod] exitMethod];

    NRMA__endMethod(controller, @selector(swizzleMe:), targetColor, trace);

    XCTAssertThrows([mockMachine verify], @"NRMA__endMethod shouldn't call [NRMATraceController exitMethod] because the trace's machine doesn't match the current one.");
    
    [mockMachine stopMocking];
    [NRMATraceController completeActivityTrace];
}


- (void) testNoSwiftInstrumentation
{
    NRMAMethodProfiler* methodProfiler = [[NRMAMethodProfiler alloc] init];

    [methodProfiler startMethodReplacement];

    NSDictionary* dict = [NRMAMethodProfiler blackWhiteDictionary];

#ifdef TARGET_OS_TV
    XCTAssertNil(dict[@"NewRelicAgentTVOSTests.NRMA__asdfasdf"], "");
#else
    XCTAssertNil(dict[@"NewRelicAgentTests.NRMA__asdfasdf"], "");
#endif
}

@end
