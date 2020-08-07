//
//  NRMAExceptionHandler.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/28/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NRMAExceptionHandler : NSObject
+ (void) logException:(NSException*)exception
                class:(NSString*)cls
             selector:(NSString*)sel;
@end
