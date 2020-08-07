//
//  NRHavesterConfiguration.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 8/27/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMADataToken.h"
#import "NRMATraceConfigurations.h"

#define kNRMA_LICENSE_KEY @"application_token"
#define kNRMA_COLLECT_NETWORK_ERRORS @"collect_network_errors"
#define kNRMA_CROSS_PROCESS_ID @"cross_process_id"
#define kNRMA_DATA_REPORT_PERIOD @"data_report_period"
#define kNRMA_DATA_TOKEN @"data_token"
#define kNRMA_ERROR_LIMIT @"error_limit"
#define kNRMA_REPORT_MAX_TRANSACTION_AGE @"report_max_transaction_age"
#define kNRMA_REPORT_MAX_TRANSACTION_COUNT @"report_max_transaction_count"
#define kNRMA_RESPONSE_BODY_LIMIT @"response_body_limit"
#define kNRMA_SERVER_TIMESTAMP @"server_timestamp"
#define kNRMA_STACK_TRACE_LIMIT @"stack_trace_limit"
#define kNRMA_AT_CAPTURE @"at_capture"
#define kNRMA_AT_MAX_SIZE @"activity_trace_max_size"
#define kNRMA_AT_MAX_SEND_ATTEMPTS @"activity_trace_max_send_attempts"
#define KNRMA_AT_MIN_UTILIZATION @"activity_trace_min_utilization"
#define kNRMA_ENCODING_KEY @"encoding_key"
#define kNRMA_ACCOUNT_ID @"account_id"
#define kNMRA_APPLICATION_ID @"application_id"

#define NRMA_DEFAULT_COLLECT_NETWORK_ERRORS YES  // boolean
#define NRMA_DEFAULT_REPORT_PERIOD 60            // seconds
#define NRMA_DEFAULT_ERROR_LIMIT 50              // errors
#define NRMA_DEFAULT_RESPONSE_BODY_LIMIT 2048    // bytes
#define NRMA_DEFAULT_STACK_TRACE_LIMIT 100       // stack frames
#define NRMA_DEFAULT_MAX_TRANSACTION_AGE 600     // seconds
#define NRMA_DEFAULT_MAX_TRANSACTION_COUNT 1000  // transactions
#define NRMA_DEFAULT_ACTIVITY_TRACE_MAX_SIZE 65535 // bytes
#define NRMA_DEFAULT_ACTIVITY_TRACE_MAX_SEND_ATTEMPTS 2 // max times to attempt to send a given AT
#define NRMA_DEFAULT_ACTIVITY_TRACE_MIN_UTILIZATION .3  // the minimum utilization of a trace, below this cut off are not reported
@interface NRMAHarvesterConfiguration : NSObject
@property(nonatomic,strong) NSString* application_token;
@property(nonatomic,assign) BOOL      collect_network_errors;
@property(nonatomic,strong) NSString* cross_process_id;
@property(nonatomic,assign) int       data_report_period;
@property(nonatomic,strong) NRMADataToken*  data_token;
@property(nonatomic,assign) int       error_limit;
@property(nonatomic,assign) int       report_max_transaction_age;
@property(nonatomic,assign) int       report_max_transaction_count;
@property(nonatomic,assign) int       response_body_limit;
@property(nonatomic,assign) long long server_timestamp;
@property(nonatomic,assign) int       stack_trace_limit;
@property(nonatomic,assign) int       activity_trace_max_size;
@property(nonatomic,assign) int       activity_trace_max_send_attempts;
@property(nonatomic,strong) NRMATraceConfigurations*  at_capture;
@property(nonatomic,assign) double    activity_trace_min_utilization;
@property(nonatomic,assign) NSString* encoding_key;
@property(nonatomic,assign) long long account_id;
@property(nonatomic,assign) long long application_id;

+ (id) defaultHarvesterConfiguration;
- (BOOL) isValid;
- (BOOL) isEqual:(id)object;
- (NSUInteger) hash;
- (id) initWithDictionary:(NSDictionary*)dict;
- (NSDictionary*) asDictionary;
@end
