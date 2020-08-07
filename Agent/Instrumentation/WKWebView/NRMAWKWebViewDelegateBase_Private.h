
//
//  Header.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/5/17.
//  Copyright © 2017 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NRWKNavigationDelegateBase.h"
@interface NRWKNavigationDelegateBase (private)
- (instancetype) initWithOriginalDelegate:(id<NSURLSessionDelegate>)delegate;
@property (nonatomic, retain, readonly) id<NSURLSessionDataDelegate> realDelegate;


@end
