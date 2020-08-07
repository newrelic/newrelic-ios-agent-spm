//
//  Created by Saxon D'Aubin on 5/23/12.
//  Copyright (c) 2012 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
/* 
    replaces the implementation of Method for class c SEL selector with newImplementation.
    this works for both class and instance methods. 
    returns the original implementation
 */
void* NRMASwapImplementations(Class c, SEL selector, IMP newImplementation);
/*
 Replaces the implementation of the given selector with the new implementation and returns a 
 pointer to the original implementation, or nil if it was not present.
 
 This method is used to replace methods on known classes.
 */

void NRMASwapOrReplaceClassMethod(Class c, SEL originalSelector, SEL newSelector);
void* NRMAReplaceInstanceMethod(Class class, SEL selector, IMP newImplementation);
/*
 Replaces the implementation of the given selector with the new implementation and returns a 
 pointer to the original implementation, or nil if it was not present.
 
 This method is used to replace class methods on known classes.
 */
void* NRMAReplaceClassMethod(Class class, SEL selector, IMP newImplementation);
/*
 If the new method is unknown by the class c, we add it to c, and replace the
 implementation of the orig method by the new implementation.
 If it's known by the class c, we just exchange the implementation.
 */
void NRMASwapOrReplaceInstanceMethod(Class c, SEL originalSelector, SEL newSelector);
/*! 
 @method         NRMASwizzleOrAddMethod
 
 @abstract
 Swaps one method implementation with another if this instance
 responds to the original selector.  Otherwise, the method implementation is
 added to the class using the original selector.
 
 Unlike the two above methods, this method is used to swap methods on classes that are not 
 known until runtime, usually protocol implementations.
 
 @discussion
 
 @param 
 origSelector     The selector for the original method
 newSelector      The selector for the method to be swapped
 
 
 @result
 
 YES         if the swizzle was successful
 
 NO            
 */
BOOL NRMASwizzleOrAddMethod(id self, SEL origSelector, SEL newSelector, IMP theImplementation);
