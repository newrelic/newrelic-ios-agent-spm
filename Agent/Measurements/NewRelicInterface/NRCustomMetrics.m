//
//  NRCustomMetrics.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 7/11/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRLogger.h"
#import "NRCustomMetrics.h"
#import "NRMAMetricSet.h"
#import "NRMAMeasurements.h"
#import "NRMATraceController.h"
#import "NRMAExceptionHandler.h"
#import "NewRelicInternalUtils.h"
#define kCustomMetricRegexPattern   @"[a-zA-Z0-9_ ]+"
#define kCustomUnitsRegexPattern    @"[a-zA-Z0-9_%/ ]+"


#define customMetricRecordFailureLog  @"Record custom metric failed."
NRMAMetricSet* __metrics;


@implementation NRCustomMetrics

//set the metric name and it's category
+ (void) recordMetricWithName:(NSString *)name
                     category:(NSString *)category
{
    [NRCustomMetrics recordMetricWithName:name
                                 category:category
                                    value:[NSNumber numberWithInt:1]];
}
//add a value to be recorded
+ (void) recordMetricWithName:(NSString *)name
                     category:(NSString *)category
                        value:(NSNumber *)value
{
    [NRCustomMetrics recordMetricWithName:name
                                 category:category
                                    value:value
                               valueUnits:nil];
}

// adds a unit for the value
/*
 * while there are a few pre-defined units please feel free to add your own by
 * typecasting an NSString.
 *
 * The unit names may be mixed case and may consist strictly of alphabetical
 * characters as well as the _, % and / symbols.Case is preserved.
 * Recommendation: Use uncapitalized words, spelled out in full.
 * For example, use second not Sec.
 */

+ (void) recordMetricWithName:(NSString *)name
                     category:(NSString *)category
                        value:(NSNumber *)value
                   valueUnits:(NRMetricUnit*)valueUnits
{
    [NRCustomMetrics recordMetricWithName:name
                                 category:category
                                    value:value
                               valueUnits:valueUnits
                               countUnits:nil];
}

//adds count units default is just "sample"
// The count is the number of times the particular metric is recorded
// so the countUnits could be considered the units of the metric itself.
+ (void) recordMetricWithName:(NSString *)name
                     category:(NSString *)category
                        value:(NSNumber *)value
                   valueUnits:(NRMetricUnit *)valueUnits
                   countUnits:(NRMetricUnit *)countUnits
{
    //here's where all the magic happens
    
    if (name == nil || category == nil) {
        NRLOG_ERROR(@"+recordMetricWithName:Category:[...] must supply a name and category.");
        return;
    }
    
    if (![NRCustomMetrics isValidMetricInput:name]) {
        NRLOG_ERROR(@"%@ Invalid name: %@ (failed match %@)",customMetricRecordFailureLog,
                    name,
                    kCustomMetricRegexPattern);
        return;
    }
    
    if (value <= 0) {
        NRLOG_ERROR(@"%@ Value must be a non-zero postive number.",customMetricRecordFailureLog);
        return;
    }
    
    if (![NRCustomMetrics isValidMetricInput:category]) {
        NRLOG_ERROR(@"%@ Invalid category: %@ (failed match %@)",customMetricRecordFailureLog,
                    name,
                    kCustomMetricRegexPattern);
        return;
    }
    
    if ([valueUnits length] && ![NRCustomMetrics isValidMetricUnit:valueUnits]) {
        NRLOG_ERROR(@"%@ Invalid valueUnits: %@ (failed match %@)",customMetricRecordFailureLog,
                    valueUnits,
                    kCustomUnitsRegexPattern);
        return;
    }
    
    if ([countUnits length] && ![NRCustomMetrics isValidMetricUnit:countUnits]) {
        NRLOG_ERROR(@"%@ Invalid countUnits: %@ (failed match %@)",customMetricRecordFailureLog,
                    countUnits,
                    kCustomUnitsRegexPattern);
        return;
    }
    

    NSString* metricName =[NSString stringWithFormat:@"Custom/%@/%@",category,name];
    
    NSString* metric = [NRCustomMetrics generateMetricStringWithName:metricName
                                                   valueUnits:valueUnits
                                                   countUnits:countUnits];
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    @try {
        #endif
        [NRCustomMetrics addMetric:metric value:value];
        NRLOG_VERBOSE(@"Added metric name: %@ with value: %@",metric,value);
#ifndef  DISABLE_NRMA_EXCEPTION_WRAPPER
    } @catch (NSException* exception) {
        [NRMAExceptionHandler logException:exception
                                   class:NSStringFromClass([self class])
                                selector:NSStringFromSelector(_cmd)];
    }
#endif
    
}


+ (void) addMetric:(NSString*)metric
             value:(NSNumber*)value
{
    if ([NSThread currentThread] == [NSThread mainThread]) {
        [NRMAMeasurements recordAndScopeMetricNamed:metric value:value];
    } else {
        [NRMAMeasurements recordBackgroundScopedMetricNamed:metric value:value];
    }
}

+ (NSString*) generateMetricStringWithName:(NSString*)name
                                valueUnits:(NSString*)valueUnits
                                countUnits:(NSString*)countUnits
{
    NSString* metricUnits = @"";
    if ([countUnits length]) {
        //creates the form [|{metricUnits}]
        metricUnits = [NSString stringWithFormat:@"|%@",countUnits];
    }
    
    if ([valueUnits length]) {
        // creates the form [{valueUnits}|{metricUnits}] or [{valueUnits}]
        metricUnits = [valueUnits stringByAppendingString:metricUnits];
    }
    
    if ([metricUnits length]) {
        metricUnits  = [NSString stringWithFormat:@"[%@]",metricUnits];
    }
    
    NSString* metricName = [NSString stringWithFormat:@"%@%@",name,metricUnits];
    return metricName;
}



#pragma mark -

+ (NRMAMetricSet*) metrics
{
    @synchronized(__metrics) {
        if (!__metrics) {
            __metrics = [[NRMAMetricSet alloc] init];
        }
        return __metrics;
    }
}


+ (NRMAMetricSet*) harvest {
    NRMAMetricSet* harvest = nil;
    @synchronized(__metrics) {
        harvest = __metrics;
        __metrics = nil;
    }
    return harvest;
}

//nil input result undefined
+ (BOOL) isValidMetricInput:(NSString*)input
{
    static NSRegularExpression* __validMetricRX;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //error only if pattern is invalid
        NSError* error;
        //TODO: test what happens if this throws an error!
        __validMetricRX = [[NSRegularExpression alloc] initWithPattern:kCustomMetricRegexPattern
                                                               options:NSRegularExpressionCaseInsensitive
                                                                 error:&error];
        if (error) {
            NRLOG_ERROR(@"Metric naming validator failed with error: %@",error);
        }
    });
    
    if (!__validMetricRX) {
        return NO;
    }
    return [NewRelicInternalUtils validateString:input usingRegularExpression:__validMetricRX];
}

//nil input result undefined
+ (BOOL) isValidMetricUnit:(NRMetricUnit*)input
{
    static NSRegularExpression* __validUnitRX;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //error only if pattern is invalid
        NSError* error;
        //TODO: test what happens if this throws an error!
        __validUnitRX = [[NSRegularExpression alloc] initWithPattern:kCustomUnitsRegexPattern
                                                             options:NSRegularExpressionCaseInsensitive
                                                               error:&error];
        if (error) {
            NRLOG_ERROR(@"Metric unit validator failed with error: %@",error);
        }
    });
    return [NewRelicInternalUtils validateString:input usingRegularExpression:__validUnitRX];
}

@end
