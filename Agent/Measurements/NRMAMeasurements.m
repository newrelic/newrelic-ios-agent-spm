//
//  NRMAMeasurements.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/26/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAMeasurements.h"
#import "NRLogger.h"
#import "NewRelicInternalUtils.h"
#import "NRMAThreadInfo.h"
#import "NRMAMeasurementEngine.h"
#import "NRMAActivityTraceMeasurementCreator.h"
#import "NRMAActivityTraceMeasurementProducer.h"
#import "NRMAHTTPTransactionMeasurementProducer.h"
#import "NRMAHarvestableHTTPTransactionGeneration.h"
#import "NRMAHarvestController.h"
#import "NRMANamedValueProducer.h"
#import "NRMAMachineMeasurementConsumer.h"
#import "NRMAMethodMeasurementProducer.h"
#import "NRMAMethodSummaryMeasurement.h"
#import "NRMASummaryMeasurementConsumer.h"
#import "NRMATraceController.h"
#import "NRMANamedValueMeasurement.h"
#import "NRMAExceptionHandler.h"
#import "NRMAMetric.h"
#import "NRMATaskQueue.h"
#import "NRConstants.h"
#import "NewRelicAgentInternal.h"

#define kBackgroundScopedMetricPrefix  @"Mobile/Activity/Background/Name"
#define kScopedMetricPrefix            @"Mobile/Activity/Name"
#define kSummaryScopeMetricPrefix      @"Mobile/Activity/Summary/Name"


static NRMAMeasurementEngine* __engine;


static BOOL __shouldBroadcastMeasurements;

@implementation NRMAMeasurements

static NSString* __NRMAEngineAccessorMutex = @"AccessorMutex";

+ (NRMAMeasurementEngine*) engine
{
    @synchronized(__NRMAEngineAccessorMutex) {
        return __engine;
    }
}

static NSString* __NRMAInitializationMutex = @"initializationMutex";

+ (void) initializeMeasurements
{
    NRLOG_INFO(@"Measurement Engine Initialized.");
    @synchronized(__NRMAInitializationMutex) {
        if (__engine) {
            return;
        }
        @synchronized(__NRMAEngineAccessorMutex) {
            __engine = [[NRMAMeasurementEngine alloc] init];
        }
        [NRMAHarvestController addHarvestListener:__engine];

        [NRMATaskQueue start];
        __shouldBroadcastMeasurements = YES;
    }
}


+ (void) shutdown
{
    @synchronized(__NRMAInitializationMutex) {
        NRLOG_INFO(@"Measurement Engine shutting down.");
        [NRMATaskQueue stop];
        [NRMAHarvestController removeHarvestListener:__engine];
        @synchronized(__NRMAEngineAccessorMutex) {
            __engine = nil;
        }
    }
}

#pragma mark - recordMetrics

+ (NSString*) recordBackgroundScopedMetricNamed:(NSString*)name
                                          value:(NSNumber*)value
{
    NSString* scope = [NRMATraceController getCurrentActivityName];
    NSString* fullScope = @"";
    if ([scope length]) {
        fullScope = [NSString stringWithFormat:@"%@/%@", kBackgroundScopedMetricPrefix,
                                               scope];
    }

    [NRMATaskQueue queue:[[NRMAMetric alloc] initWithName:name
                                                    value:value
                                                    scope:fullScope]];

    return fullScope;
}

+ (void) recordNetworkMetricsFromMetrics:(NSArray*)metrics
                             forActivity:(NSString*)activityName
{
    double networkingDurationSum = 0;
    int count = 0;

    for (NRMAMeasurement* measurement in metrics) {
        if (![measurement isKindOfClass:[NRMAMeasurement class]]) {
            continue;
        }

        if(measurement.type != NRMAMT_HTTPTransaction
           && measurement.type != NRMAMT_Network) {
            continue;
        }

        count++;
        double networkingDuration = measurement.endTime - measurement.startTime;
        if(networkingDuration > 0){
            networkingDurationSum += networkingDuration;
        }
    }
    [NRMATaskQueue queue:[[NRMAMetric alloc] initWithName:[NSString stringWithFormat:@"%@/%@/%@",
                                                           kNRMAMetricActivityNetworkPrefix,
                                                           activityName,
                                                           kNRMAMetricSuffixCount]
                                                    value:@(count)
                                                    scope:@""]];
    
    [NRMATaskQueue queue:[[NRMAMetric alloc] initWithName:[NSString stringWithFormat:@"%@/%@/%@",
                                                           kNRMAMetricActivityNetworkPrefix,
                                                           activityName,
                                                           kNRMAMetricSuffixTime]
                                                    value:@(networkingDurationSum*kNRMASecondsPerMillisecond)
                                                    scope:@""]];
}

+ (NSString*) recordAndScopeMetricNamed:(NSString*)name
                                  value:(NSNumber*)value
{

    NSString* scope = [NRMATraceController getCurrentActivityName];
    NSString* fullScope = @"";
    if ([scope length]) {
        fullScope = [NSString stringWithFormat:@"%@/%@", kScopedMetricPrefix,
                                               scope];
    }

    [NRMATaskQueue queue:[[NRMAMetric alloc] initWithName:name
                                                    value:value
                                                    scope:fullScope]];

    return fullScope;
}

+ (void) recordMetric:(NRMAMetric*)metric
{
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif
        if (metric.produceUnscopedMetrics) {
            NRMANamedValueMeasurement* namedValue = [[NRMANamedValueMeasurement alloc] initWithName:metric.name
                                                                                              value:metric.value];
            [[NRMAMeasurements engine].machineMeasurementsProducer produceMeasurement:namedValue];
        }
        if ([metric.scope length]) {
            NRMANamedValueMeasurement* namedValue = [[NRMANamedValueMeasurement alloc] initWithName:metric.name
                                                                                              value:metric.value];
            namedValue.scope = metric.scope;
            [[NRMAMeasurements engine].machineMeasurementsProducer produceMeasurement:namedValue];
        }

        [NRMAMeasurements broadcastMeasurements];

#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                     class:NSStringFromClass([NRMAMeasurements class])
                                  selector:NSStringFromSelector(_cmd)];

        @throw [NSException exceptionWithName:kNRMAMetricException
                                       reason:@"Recieved an exception trying to generate metrics"
                                     userInfo:@{@"name" : metric.name,
                                             @"value" : metric.value,
                                             @"scope" : metric.scope,
                                             @"shouldProduceUnscoped" : metric.produceUnscopedMetrics?@"YES":@"NO"}]; //rethrow so other modules can handle the exception
    }
#endif

}

+ (void) recordSessionStartMetric
{
    NRLOG_VERBOSE(@"Recording Session Start Metric.");
    [NRMAMeasurements recordMetric:[[NRMAMetric alloc] initWithName:kNRMASessionStartMetric
                                                              value:@1
                                                              scope:nil]];
}

#pragma mark - ActivityTraces

+ (void) recordActivityTrace:(NRMAActivityTrace*)activityTrace
{
    if ([[[NewRelicAgentInternal sharedInstance] getAppSessionStartDate] timeIntervalSince1970] > (activityTrace.startTime / 1000)) {
        NRLOG_VERBOSE(@"Ignoring activity trace which started before current session start.");
        return;
    }
    
    if ([NRMAHarvestController shouldNotCollectTraces]) {
        [NRMATaskQueue queue:[[NRMAMetric alloc] initWithName:kNRSupportabilityPrefix@"/ActivityTracesDropped"
                                                        value:@1
                                                        scope:@""]];
        NRLOG_VERBOSE(@"Maximum number of Activity Traces collected. Skipping");
        return;
    }

#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif
        [[NRMAMeasurements engine].activityTraceMeasurementProducer produceMeasurementWithTrace:activityTrace];
        [NRMAMeasurements broadcastMeasurements];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                     class:NSStringFromClass([NRMAMeasurements class])
                                  selector:NSStringFromSelector(@selector(recordActivityTrace:))];
    }
#endif
}

+ (void) recordSummaryMeasurements:(NRMATrace*)trace
{
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif
        NRMAMethodSummaryMeasurement* methodSummaryMeasurement = [[NRMAMethodSummaryMeasurement alloc] initWithName:trace.name
                                                                                                              scope:@""
                                                                                                          startTime:trace.entryTimestamp
                                                                                                            endtime:trace.exitTimestamp
                                                                                                      exclusiveTime:trace.exclusiveTimeMillis
                                                                                                      traceCategory:trace.category];
        [[NRMAMeasurements engine].summaryMeasurementProducer produceMeasurement:methodSummaryMeasurement];

        [NRMAMeasurements broadcastMeasurements];

#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                     class:NSStringFromClass([NRMAMeasurements class])
                                  selector:NSStringFromSelector(@selector(recordSummaryMeasurements:))];
    }
#endif


}

#pragma mark - HTTPError

+ (void) recordHTTPError:(NRMAHTTPError*)error
{
    [NRMAMeasurements recordHTTPError:error.url
                       httpMethod:error.httpMethod
                      timeOfError:error.timeOfErrorMillis
                       statusCode:error.statusCode
                     responseBody:error.response
                       parameters:error.parameters
                          wanType:error.wanType
                          appData:error.appData
                       threadInfo:error.threadInfo];
}

+ (void) recordHTTPError:(NSString*)url
              httpMethod:(NSString*)httpMethod
             timeOfError:(double)toe
              statusCode:(int)statusCode
            responseBody:(NSString*)response
              parameters:(NSDictionary*)parameters
                 wanType:(NSString*)wanType
                 appData:(NSString*)appData
              threadInfo:(NRMAThreadInfo*)threadInfo
{
    [[NRMAMeasurements engine].httpErrorMeasurementProducer produceMeasurementWithURL:url
                                                                       httpMethod:httpMethod
                                                                      timeOfError:toe
                                                                       statusCode:statusCode
                                                                         response:response
                                                                          wanType:wanType
                                                                          appData:appData
                                                                       parameters:parameters];
    [NRMAMeasurements broadcastMeasurements];
}

#pragma mark - HTTP Transaction

+ (void) recordHTTPTransaction:(NRMAHTTPTransaction*)transaction
{
    [NRMAMeasurements recordHTTPTransactionWithURL:transaction.url
                                    httpMethod:transaction.httpMethod
                                     startTime:transaction.startTimeMillis
                                     totalTime:transaction.totalTimeMillis
                                     bytesSent:transaction.dataSentBytes
                                 bytesReceived:transaction.dataReceivedBytes
                                    statusCode:transaction.statusCode
                                   failureCode:transaction.failureCode
                                       appData:transaction.crossProccessResponse
                                       wanType:transaction.wanType
                                    threadInfo:transaction.threadInfo];
}

+ (void) recordHTTPTransactionWithURL:(NSString*)url
                           httpMethod:(NSString*)httpMethod
                            startTime:(double)startTime
                            totalTime:(double)totalTime
                            bytesSent:(long long)bytesSent
                        bytesReceived:(long long)bytesReceived
                           statusCode:(int)statusCode
                          failureCode:(int)failureCode
                              appData:(NSString*)appdata
                              wanType:(NSString*)wanType
                           threadInfo:(NRMAThreadInfo*)threadInfo
{


    NSString* carrierName = @"unknown";
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif
        carrierName = [NewRelicInternalUtils carrierName];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                     class:NSStringFromClass([NewRelicInternalUtils class])
                                  selector:@"carrierName"];
    }
#endif
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif
        [[NRMAMeasurements engine].httpTransactionMeasurementProducer produceHttpTransaction:url
                                                                              httpMethod:httpMethod
                                                                                 carrier:carrierName
                                                                               startTime:startTime
                                                                               totalTime:totalTime
                                                                              statusCode:statusCode
                                                                               errorCode:failureCode
                                                                               bytesSent:bytesSent
                                                                           bytesReceived:bytesReceived
                                                                                 appData:appdata
                                                                                 wanType:wanType
                                                                              threadInfo:threadInfo];
        [NRMAMeasurements broadcastMeasurements];

#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                     class:NSStringFromClass([[NRMAMeasurements engine].httpTransactionMeasurementProducer class])
                                  selector:@"produceHttpTransaction:carrier:startTime:totalTime:statusCode:errorCode:bytesSent:bytesRecieved:appData:"];
    }
#endif
}

#pragma mark


+ (void) broadcastMeasurements
{
    if (__shouldBroadcastMeasurements) {
        [NRMAMeasurements process];
    }
}

static NSString* __processLock;

+ (void) process
{
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif
        @synchronized(__processLock) {
            [[NRMAMeasurements engine] broadcastMeasurements];
        }
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                     class:NSStringFromClass([NRMAMeasurements class])
                                  selector:NSStringFromSelector(_cmd)];


    }
#endif
}

+ (void) addMeasurementConsumer:(id<NRMAConsumerProtocol>)consumer
{

#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif
        [[NRMAMeasurements engine] addMeasurementConsumer:consumer];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                     class:NSStringFromClass([NRMAMeasurements class])
                                  selector:NSStringFromSelector(_cmd)];
    }
#endif
}

+ (void) removeMeasurementConsumer:(id<NRMAConsumerProtocol>)consumer
{
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif
        [[NRMAMeasurements engine] removeMeasurementConsumer:consumer];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                     class:NSStringFromClass([NRMAMeasurements class])
                                  selector:NSStringFromSelector(_cmd)];
    }
#endif
}

+ (void) addMeasurementProducer:(id<NRMAProducerProtocol>)producer
{
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif
        [[NRMAMeasurements engine] addMeasurementProducer:producer];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                     class:NSStringFromClass([NRMAMeasurements class])
                                  selector:NSStringFromSelector(_cmd)];
    }
#endif
}

+ (void) removeMeasurementProducer:(id<NRMAProducerProtocol>)producer
{
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif
        [[NRMAMeasurements engine] removeMeasurementProducer:producer];

#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                     class:NSStringFromClass([NRMAMeasurements class])
                                  selector:NSStringFromSelector(_cmd)];
    }
#endif
}

+ (void) processCurrentSummaryMetricsWithTotalTime:(double)timeMillis
                                      activityName:(NSString*)name
{
    NSString* summaryMetricScope = [NSString stringWithFormat:@"%@/%@", kSummaryScopeMetricPrefix,
                                                              name];

    [NRMATaskQueue queue:[[NRMAMetric alloc] initWithName:summaryMetricScope
                                                    value:@(timeMillis / (double)1000)
                                                    scope:nil]];

#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
#endif
        [[NRMAMeasurements engine].summaryMeasurementConsumer aggregateAndNormalizeAndRecordValuesWithTotalTime:timeMillis
                                                                                                      scope:summaryMetricScope];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                     class:NSStringFromClass([[NRMAMeasurements engine].summaryMeasurementConsumer class])
                                  selector:@"aggregateAndNormalizeAndRecordValuesWithTotalTime:scope:"];
    }
#endif
}

#pragma mark - test helpers

+ (NRMAActivityTraceMeasurementProducer*) activityTraceMeasurementProducer
{
    return [NRMAMeasurements engine].activityTraceMeasurementProducer;
}

+ (NRMAHTTPTransactionMeasurementProducer*) httpTransactionMeasurementProducer
{
    return [NRMAMeasurements engine].httpTransactionMeasurementProducer;
}

+ (void) setBroadcastNewMeasurements:(BOOL)enabled
{
    __shouldBroadcastMeasurements = enabled;
}

@end

@implementation NRMAMeasurementEngine (extension)

#pragma mark - harvest aware

- (void) onHarvestBefore
{
    //fetch machine measurements before harvest!
    [self.machineMeasurementsProducer generateMachineMeasurements];
    [NRMATaskQueue synchronousDequeue];
}

@end
