//
//  NSArray+WMFShuffle.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/30/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSArray+WMFShuffle.h"

@implementation NSArray (WMFShuffle)

- (instancetype)wmf_shuffledCopy {
    return [[[self mutableCopy] wmf_shuffle] copy];
}

@end

@implementation NSMutableArray (WMFShuffle)

- (instancetype)wmf_shuffle {
    for (int i = 0; i < self.count; i++) {
        int swapIndex = arc4random_uniform((uint32_t)self.count);
        [self exchangeObjectAtIndex:i withObjectAtIndex:swapIndex];
    }
    return self;
}

@end
