//
//  CircularBitwiseRotationTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "WMFHashing.h"

@interface CircularBitwiseRotationTests : XCTestCase

@end

@implementation CircularBitwiseRotationTests

- (void)testMatchesCorrespondingPowerOfTwo {
    for (NSUInteger rotation; rotation < NSUINT_BIT; rotation++) {
        NSUInteger actualResult = flipBitsWithAdditionalRotation(1, rotation);
        // add by NSUINT_BIT_2 to model the "flipping," then modulo for rotation
        NSUInteger exponent       = (rotation + NSUINT_BIT_2) % NSUINT_BIT;
        NSUInteger expectedResult = powl(2, exponent);
        XCTAssertEqual(actualResult, expectedResult,
                       @"Rotating 1 by %lu should be equal to 2^%lu (%lu). Got %lu instead",
                       rotation, exponent, expectedResult, actualResult);
    }
}

- (void)testSymmetrical {
    for (NSUInteger i; i < 50; i++) {
        NSUInteger testValue = arc4random();
        for (NSUInteger rotation; rotation < NSUINT_BIT; rotation++) {
            NSUInteger symmetricalRotation = rotation + NSUINT_BIT;
            NSUInteger original            = flipBitsWithAdditionalRotation(testValue, rotation);
            NSUInteger symmetrical         = flipBitsWithAdditionalRotation(testValue, symmetricalRotation);
            XCTAssertEqual(original, symmetrical,
                           @"Rotating %lu by %lu should be the same as rotating by %lu + NSUINT_BIT (%lu)."
                           "Got %lu expected %lu",
                           testValue, rotation, rotation, symmetricalRotation, symmetrical, original);
        }
    }
}

@end
