//
//  NRMANSURLConnectionDelegateBase.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/21/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NRMANSURLConnectionDelegateBase : NSObject <NSURLConnectionDataDelegate,NSURLConnectionDelegate>
@property (nonatomic, retain, readwrite) id<NSURLConnectionDelegate> realDelegate;
@property (nonatomic, retain, readwrite) NSURLRequest* request;
@property (nonatomic, readonly)  NSURLResponse* response;
@property (nonatomic, readonly)  NSData* responseData;

- (void)startDownloadTimer;

@end
