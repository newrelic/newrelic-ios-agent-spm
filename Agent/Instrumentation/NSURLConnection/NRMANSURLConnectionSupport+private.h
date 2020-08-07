//
//  NRMANSURLConnectionSupport+private.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/21/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMANSURLConnectionSupport.h"
#import "NRTimer.h"


@interface NRMANSURLConnectionSupport (private)
+ (void)noticeResponse:(NSURLResponse *)response
forRequest:(NSURLRequest *)request
withTimer:(NRTimer *)timer
andBody:(NSData *)body
bytesSent:(NSUInteger)sent
bytesReceived:(NSUInteger)received;

+ (void)noticeError:(NSError*)error
         forRequest:(NSURLRequest *)request
          withTimer:(NRTimer *)timer;
@end
