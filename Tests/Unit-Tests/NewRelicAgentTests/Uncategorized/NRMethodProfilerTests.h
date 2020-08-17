//
//  NRMAMethodProfilerTests.h
//  NewRelicAgent
//
//  Created by Jeremy Templier on 5/23/13.
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NRMAMethodProfiler.h"
@interface SuperSwizzle : NSObject

@property (nonatomic,strong) NSMutableArray* calls;
- (void)swizzleMe:(BOOL)text;
@end

@interface SwizzleParent : SuperSwizzle
- (void)swizzleMe:(BOOL)text;
@end

@interface SwizzleChild : SwizzleParent
@end

@interface NRMASubChild : SwizzleChild
@end



@interface NRMAMethodProfilerTests : XCTestCase
{
    NSMutableSet* set;
}
@end
