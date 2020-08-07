//
//  NSObject+NRMAAssociatedObject.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 10/29/13.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>


void NRMA_pushActingClass(id self, NSString* selector, Class cls);
Class NRMA_popActingClass(id self,NSString* selector);
Class NRMA_actingClass(id self, NSString* selector);
NSMutableArray* NRMA_actingClassArray(id self, NSString* selector);
