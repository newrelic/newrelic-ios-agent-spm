//
//  NRMAHavesterConfiguration.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/27/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import "NRMAHarvesterConfiguration.h"

@implementation NRMAHarvesterConfiguration

/*
{
    "collect_network_errors" = 1;
    "cross_process_id" = VQ8HQlVVAQEA;
    "data_report_period" = 60;
    "data_token" =     (
                        36920,
                        36921
                        );
    "error_limit" = 50;
    "report_max_transaction_age" = 600;
    "report_max_transaction_count" = 1000;
    "response_body_limit" = 2048;
    "server_timestamp" = 1376265600;
    "stack_trace_limit" = 100;
    "encoding_key" = "d67afc830dab717fd163bfcb0b8b88423e9a1a3b";
    "account_id" = "340262";
    "application_id" = "257421";
}*/
- (id) initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    if (self) {
        self.application_token = [dict valueForKey:kNRMA_LICENSE_KEY];
        self.collect_network_errors = [[dict valueForKey:kNRMA_COLLECT_NETWORK_ERRORS] boolValue];
        self.cross_process_id = [dict valueForKey:kNRMA_CROSS_PROCESS_ID];
        self.data_report_period = [[dict valueForKey:kNRMA_DATA_REPORT_PERIOD] intValue];
        self.data_token = [[NRMADataToken alloc] init];
        self.data_token.clusterAgentId  = [[[dict valueForKey:kNRMA_DATA_TOKEN] objectAtIndex:0] longLongValue];
        self.data_token.realAgentId = [[[dict valueForKey:kNRMA_DATA_TOKEN] objectAtIndex:1] longLongValue];
        self.error_limit = [[dict valueForKey:kNRMA_ERROR_LIMIT] intValue];
        self.report_max_transaction_age = [[dict valueForKey:kNRMA_REPORT_MAX_TRANSACTION_AGE] intValue];
        self.report_max_transaction_count = [[dict valueForKey:kNRMA_REPORT_MAX_TRANSACTION_COUNT]intValue];
        self.response_body_limit = [[dict valueForKey:kNRMA_RESPONSE_BODY_LIMIT] intValue];
        self.server_timestamp = [[dict valueForKey:kNRMA_SERVER_TIMESTAMP] longLongValue];
        self.stack_trace_limit = [[dict valueForKey:kNRMA_STACK_TRACE_LIMIT] intValue];
        self.activity_trace_max_size =[[dict valueForKey:kNRMA_AT_MAX_SIZE] intValue];
        self.at_capture = [[NRMATraceConfigurations alloc] initWithArray:[dict valueForKey:kNRMA_AT_CAPTURE]];
        self.activity_trace_min_utilization = [[dict valueForKey:KNRMA_AT_MIN_UTILIZATION] doubleValue];
        self.encoding_key = [dict valueForKey:kNRMA_ENCODING_KEY];
        self.account_id = [[dict valueForKey:kNRMA_ACCOUNT_ID] longLongValue];
        self.application_id = [[dict valueForKey:kNMRA_APPLICATION_ID] longLongValue];
        // The collector does not currently send down this key, but we still want a sane default
        if ([dict objectForKey:kNRMA_AT_MAX_SEND_ATTEMPTS]) {
            self.activity_trace_max_send_attempts = [[dict valueForKey:kNRMA_AT_MAX_SEND_ATTEMPTS] intValue];
        } else {
            self.activity_trace_max_send_attempts = NRMA_DEFAULT_ACTIVITY_TRACE_MAX_SEND_ATTEMPTS;
        }
    }
    return self;
}

+ (id) defaultHarvesterConfiguration
{
    NRMAHarvesterConfiguration *configuration = [[NRMAHarvesterConfiguration alloc] init];
    configuration.collect_network_errors = NRMA_DEFAULT_COLLECT_NETWORK_ERRORS;
    configuration.data_report_period = NRMA_DEFAULT_REPORT_PERIOD;
    configuration.error_limit = NRMA_DEFAULT_ERROR_LIMIT;
    configuration.report_max_transaction_age = NRMA_DEFAULT_MAX_TRANSACTION_AGE;
    configuration.report_max_transaction_count = NRMA_DEFAULT_MAX_TRANSACTION_COUNT;
    configuration.response_body_limit = NRMA_DEFAULT_RESPONSE_BODY_LIMIT;
    configuration.stack_trace_limit = NRMA_DEFAULT_STACK_TRACE_LIMIT;
    configuration.activity_trace_max_size = NRMA_DEFAULT_ACTIVITY_TRACE_MAX_SIZE;
    configuration.activity_trace_max_send_attempts = NRMA_DEFAULT_ACTIVITY_TRACE_MAX_SEND_ATTEMPTS;
    configuration.activity_trace_min_utilization = NRMA_DEFAULT_ACTIVITY_TRACE_MIN_UTILIZATION;
    configuration.at_capture = [NRMATraceConfigurations defaultTraceConfigurations];
    return configuration;
}

- (BOOL) isValid
{
    return self.data_token.isValid && self.account_id > 0 && self.application_id > 0;
}

- (NSDictionary*) asDictionary
{
    NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] initWithCapacity:15];
    dictionary[kNRMA_LICENSE_KEY] = self.application_token;
    dictionary[kNRMA_COLLECT_NETWORK_ERRORS] = @(self.collect_network_errors);
    if ([self.cross_process_id length]) {
        dictionary[kNRMA_CROSS_PROCESS_ID] = self.cross_process_id;
     }
    
    dictionary[kNRMA_DATA_REPORT_PERIOD] = @(self.data_report_period);
    
    dictionary[kNRMA_DATA_TOKEN] = @[@(self.data_token.clusterAgentId),
            @(self.data_token.realAgentId)];
    
    dictionary[kNRMA_ERROR_LIMIT] = @(self.error_limit);
    dictionary[kNRMA_REPORT_MAX_TRANSACTION_AGE] = @(self.report_max_transaction_age);
     
    dictionary[kNRMA_REPORT_MAX_TRANSACTION_COUNT] = @(self.report_max_transaction_count);
    dictionary[kNRMA_RESPONSE_BODY_LIMIT] = @(self.response_body_limit);
    dictionary[kNRMA_SERVER_TIMESTAMP] = @(self.server_timestamp);
    dictionary[kNRMA_STACK_TRACE_LIMIT] = @(self.stack_trace_limit);
    dictionary[kNRMA_AT_MAX_SIZE] = @(self.activity_trace_max_size);
    dictionary[kNRMA_AT_MAX_SEND_ATTEMPTS] = @(self.activity_trace_max_send_attempts);
    dictionary[KNRMA_AT_MIN_UTILIZATION] = @(self.activity_trace_min_utilization);
    dictionary[kNRMA_AT_CAPTURE] = @[[NSNumber numberWithInt:self.at_capture.maxTotalTraceCount], self.at_capture.activityTraceConfigurations?:@[]];
    dictionary[kNMRA_APPLICATION_ID] = @(self.application_id);
    dictionary[kNRMA_ACCOUNT_ID] = @(self.account_id);
    dictionary[kNRMA_ENCODING_KEY] = self.encoding_key;
    return dictionary;
}

- (BOOL) isEqual:(id)object {
    if (self == object) return YES;
    if (object == nil || ![object isKindOfClass:self.class]) return NO;
    NRMAHarvesterConfiguration* that = (NRMAHarvesterConfiguration*)object;
    if (self.application_token != that.application_token) return NO;
    if (self.collect_network_errors != that.collect_network_errors) return NO;
    if (self.data_report_period != that.data_report_period) return NO;
    if (self.error_limit != that.error_limit) return NO;
    if (self.report_max_transaction_age != that.report_max_transaction_age)return NO;
    if (self.report_max_transaction_count != that.report_max_transaction_count) return NO;
    if (self.response_body_limit != that.response_body_limit) return NO;
    if (self.server_timestamp != that.server_timestamp) return NO;
    if (self.stack_trace_limit != that.stack_trace_limit) return NO;
    if (![self.cross_process_id isEqualToString:that.cross_process_id]) return NO;
    if (self.activity_trace_max_size != that.activity_trace_max_size) return NO;
    if (self.activity_trace_max_send_attempts != that.activity_trace_max_send_attempts) return NO;
    if (self.activity_trace_min_utilization != that.activity_trace_min_utilization) return NO;
    if (self.account_id != that.account_id) return NO;
    if (self.application_id != that.application_id) return NO;
    if (![self.encoding_key isEqualToString:that.encoding_key]) return NO;

    return [self.data_token isEqual:that.data_token]; // [ <account id> , <app id> ];
}

- (NSUInteger) hash
{
    NSUInteger result = self.collect_network_errors ? 1 : 0;
    result = 31 * result + self.application_token.hash;
    result = 31 * result + self.cross_process_id.hash;
    result = 31 * result + self.data_report_period;
    result = 31 * result + self.data_token.hash;
    result = 31 * result + self.error_limit;
    result = 31 * result + self.report_max_transaction_age;
    result = 31 * result + self.report_max_transaction_count;
    result = 31 * result + self.response_body_limit;
    result = 31 * result + (int)(self.server_timestamp ^ (self.server_timestamp >> 32));
    result = 31 * result + self.stack_trace_limit;
    result = 31 * result + self.activity_trace_max_size;
    result = 31 * result + self.activity_trace_max_send_attempts;
    result = 31 * result + self.account_id;
    result = 31 * result + self.application_id;
    result = 31 * result + self.encoding_key.hash;
    
    return result;
}
@end
