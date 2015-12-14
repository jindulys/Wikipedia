//
//  MWKRandom.h
//  Wikipedia
//
//  Created by Brian Gerstle on 10/15/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Protocol for easily creating arbitrary and unique instances of model objects.
 *
 *  Use this to reduce tedious creation of model objects when you don't have specific requirements for
 *  their properties.
 */
@protocol MWKRandom <NSObject>

/// A unique instance of the receiver.
+ (instancetype)random;

@end
