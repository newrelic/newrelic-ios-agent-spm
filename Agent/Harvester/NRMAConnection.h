//
// Created by Bryce Buchanan on 5/2/17.
// Copyright (c) 2017 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NRMAConnectInformation;


@interface NRMAConnection : NSObject
@property(strong) NSString*             applicationToken;
@property(strong) NSString*             applicationVersion;
@property(assign) BOOL                  useSSL;

- (NSMutableURLRequest*) newPostWithURI:(NSString*)uri;
@end
