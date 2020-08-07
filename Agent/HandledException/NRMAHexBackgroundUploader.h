//
// Created by Bryce Buchanan on 7/7/17.
// Copyright (c) 2017 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAConnection.h"

@interface NRMAHexBackgroundUploader : NRMAConnection<NSURLSessionDelegate>
@property(strong) NSString* hexHost;

- (instancetype) initWithHexHost:(NSString*)hexHost;

- (void) sendData:(NSData*)data;
@end
