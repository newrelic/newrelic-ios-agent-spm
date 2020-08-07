//
//  NRMACollectionViewInstrumentation.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/28/18.
//  Copyright © 2018 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NRMACollectionViewInstrumentation : NSObject
+ (BOOL) instrument;
+ (BOOL) deinstrument;
@end
