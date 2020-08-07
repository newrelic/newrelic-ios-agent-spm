//
//  NRMAGestureRecognizerInstrumentation.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/14/16.
//  Copyright © 2016 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 *  This class instruments several methods on UIGestureRecognizer to capture
 *  data for TrackedGestures.
 */

@interface NRMAGestureRecognizerInstrumentation : NSObject
+ (BOOL) instrumentUIGestureRecognizer;
+ (BOOL) deinstrumentUIGestureRecognizer;
@end
