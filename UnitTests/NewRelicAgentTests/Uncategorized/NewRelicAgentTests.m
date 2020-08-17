//
//  NewRelicAgentTests.m
//  NewRelicAgentTests
//
//  Created by Saxon D'Aubin on 6/20/12.
//  Copyright (c) 2012 New Relic. All rights reserved.
//

#import "NewRelicAgentTests.h"
#import "NewRelicInternalUtils.h"

@implementation WaitBlock

@synthesize condition;
@synthesize completed;
@synthesize started;
@synthesize timeout;

@end



static MonitorURLProtocol *_sharedMonitor;

@implementation MonitorURLProtocol

@synthesize capturedRequests;

- (id)init {
    self = [super init];
    if (self) {
        self.capturedRequests = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)clearHeaders
{
    [self.capturedRequests removeAllObjects];
}


+ (MonitorURLProtocol *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedMonitor = [[MonitorURLProtocol alloc] init];
    });
    return _sharedMonitor;
}

/*
 Overridden from NSURLProtocol.
 */
+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    [[MonitorURLProtocol sharedInstance].capturedRequests addObject:[request copy]];

    return NO;
}

@end


@implementation RequestDelegateBase

@synthesize requestComplete = _requestComplete;
@synthesize request = _request;
@synthesize response = _response;
@synthesize error = _error;

//- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)inResponse
//{
//    self.request = connection.currentRequest;
//    self.response = (NSHTTPURLResponse*)inResponse;
//}
//
//- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
//{
//    self.request = connection.currentRequest;
//    self.requestComplete = YES;
//}
//
//- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
//{
//    self.request = connection.currentRequest;
//    self.error = error;
//    self.requestComplete = YES;
//}
//
//- (void)blockUntilDone:(NewRelicAgentTests*)test
//{
//    NSRunLoop *theRL = [NSRunLoop currentRunLoop]; 
//    NSDate* soon = [NSDate dateWithTimeIntervalSinceNow:20];
//    while (!self.requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:soon]);
//}

@end




@implementation RequestDelegate

@end

#pragma mark Methods to override the NRMAReachability currentReachabilityStatus method

NetworkStatus ReachableViaWWANMethod() {
    return ReachableViaWWAN;
}

NetworkStatus NotReachableMethod() {
    return NotReachable;
}

#ifndef DISABLE_BORKED_TESTS
static NSString *deviceId = nil;
#endif 

@implementation NewRelicAgentTests

- (void)setUp
{
    [super setUp];
    
//    [self clearDisableFlag];
//        
//    [NewRelicAgentInternal engageTestMode];
//    [NewRelicAgentInternal setApplicationName:@"UnitTests" andVersion:@"1.0" andBundleId:TEST_BUNDLE_ID];
//
//    [NewRelicAgent startWithApplicationToken:TEST_APPLICATION_TOKEN andCollectorAddress:TEST_COLLECTOR_HOST withSSL:NO];
//    
//    [[NewRelicAgentInternal sharedInstance] resetMetrics];
//
//#ifndef DISABLE_BORKED_TESTS
//    // ensure we maintain the same UDID throughout the unit test runs
//    NSString *udid = [NewRelicInternalUtils deviceId];
//    if (deviceId) {
//        STAssertTrue([deviceId isEqualToString:udid], @"udid has changed from %@ to %@", deviceId, udid);
//    }
//    else {
//        deviceId = udid;
//    }
//#endif
}

- (void)tearDown
{
    // Tear-down code here.
    //[[NewRelicAgentInternal sharedInstance] clearState];
    [[NewRelicAgentInternal sharedInstance] destroyAgent];
    
    [super tearDown];
}


-(void)clearDisableFlag
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"NewRelicAgentDisabledVersion"];
    [defaults synchronize];
}

// the async handler that evaluates a wait condition on a nested runloop and pops the nest once the condition is satisfied or the timeout expires
- (void)waitTimer:(NSTimer *)timer
{
    WaitBlock *wb = timer.userInfo;
    if (! wb.started) {
        wb.started = [[NSDate alloc] init];
    }
    
    if (wb.condition()) {
        wb.completed = YES;
        CFRunLoopStop(CFRunLoopGetCurrent());
    }
    
    else if ([[[NSDate alloc] init] timeIntervalSinceDate:wb.started] > wb.timeout) {
        CFRunLoopStop(CFRunLoopGetCurrent());
    }
}

// runloop helper that will block until a condition evaluates to true or times out while pumping the main runloop
- (void)waitForCondition:(ConditionalBlock)condition withTimeout:(NSTimeInterval)timeout
{
    // setup a waitblock to wrap the condition we are testing for
    WaitBlock *wb = [[WaitBlock alloc] init];
    wb.condition = condition;
    wb.completed = NO;
    wb.started = nil;
    wb.timeout = timeout;
    
    // create a timer that will fire our test method every tenth of a second
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                      target:self
                                                    selector:@selector(waitTimer:)
                                                    userInfo:wb
                                                     repeats:YES];
    // suspend this function and cause the thread's run loop to pump events in a nested context.
    // the test method will pop the run loop context once it is finished, which will cause us to resume
    CFRunLoopRun();
    
    [timer invalidate];
    
    STAssertTrue(wb.completed, @"waitForCondition timed out after %.1f seconds!", timeout);
}

- (void)waitForData
{
    return [self waitForDataExists:true];
}

- (void)waitForDataExists:(BOOL)exists
{
    NewRelicAgentInternal *agent = [NewRelicAgentInternal sharedInstance];
    ConditionalBlock cb = ^{
        if (agent == nil) return NO;
        if (exists == (agent.transactionData.count > 0)) return YES;
        return NO;
    };
    
    [self waitForCondition:cb withTimeout:15];
}

- (void)waitForCountedTransactions:(NSUInteger)count withTimeout:(NSTimeInterval)timeout
{
    NewRelicAgentInternal *agent = [NewRelicAgentInternal sharedInstance];
    ConditionalBlock cb = ^{
        if (agent == nil) return NO;
        if (count == agent.transactionData.count) return YES;
        return NO;
    };

    [self waitForCondition:cb withTimeout:timeout];
}

- (void)hitGoogle
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com/"]
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                         timeoutInterval:5.0];
    NSURLResponse* response = nil;
    NSError* error = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
}

- (void)hitGoogleWithError
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com/foobarnonexistent"]
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                         timeoutInterval:5.0];
    NSURLResponse* response = nil;
    NSError* error = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
}

- (NSMutableURLRequest*)createRequest
{
    return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:TEST_URL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5.0];
}



- (void)generateRealDataAndWait
{
    NSMutableURLRequest *request = [self createRequest];
    NSURLResponse* response = nil;
    NSError* error = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    // hmm..  we process the response asynchronously.  this code waits for that async processing to occur
    [self waitForData];
}


- (void)checkResponseHeadersIndirect:(NSDictionary *)dictionary {
    CHECK_AGENT_RESPONSE_HEADERS(dictionary)
}


@end
