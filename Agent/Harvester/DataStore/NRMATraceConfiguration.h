//
//  NRMATraceConfiguration.h
//  NewRelicAgent
//
//  Created by Jared Stanbrough on 10/10/13.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NRMATraceConfiguration : NSObject
@property(nonatomic,strong) NSString*           activityTraceNamePattern;
@property(nonatomic,assign) int                 totalTraceCount;
@end
