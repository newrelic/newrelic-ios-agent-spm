//
//  NRMACrashReport_CodeType.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/6/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRMAJSON.h"

#define kNRMA_CR_archKey            @"arch"
#define kNRMA_CR_typeEncodingKey    @"typeEncoding"

@interface NRMACrashReport_CodeType : NSObject <NRMAJSONABLE>
@property(strong) NSString* arch;
@property(strong) NSString* typeEncoding;

- (instancetype) initWithArch:(NSString*)arch
                 typeEncoding:(NSString*)typeEncoding;

@end
