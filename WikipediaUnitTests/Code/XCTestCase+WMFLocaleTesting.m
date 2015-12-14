//
//  XCTestCase+WMFLocaleTesting.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "XCTestCase+WMFLocaleTesting.h"
#import <BlocksKit/BlocksKit.h>
#import "WMFAsyncTestCase.h"

@implementation XCTestCase (WMFLocaleTesting)

- (void)wmf_runParallelTestsWithLocales:(NSArray*)localeIdentifiers block:(WMFLocaleTest)block {
    [self wmf_runParallelTestsWithLocales:localeIdentifiers
                                  timeout:localeIdentifiers.count * WMFDefaultExpectationTimeout
                                    block:block];
}

- (void)wmf_runParallelTestsWithLocales:(NSArray*)localeIdentifiers
                                timeout:(NSTimeInterval)timeout
                                  block:(WMFLocaleTest)block {
    NSDictionary* expectationsForLocale =
        [localeIdentifiers bk_reduce:[NSMutableDictionary dictionaryWithCapacity:localeIdentifiers.count]
                           withBlock:^id (NSMutableDictionary* sum, NSString* localeID) {
        sum[localeID] = [self expectationWithDescription:localeID];
        return sum;
    }];
    dispatch_queue_t concurrentBackgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_apply(localeIdentifiers.count, concurrentBackgroundQueue, ^(size_t i) {
        NSString* localeID = localeIdentifiers[i];
        NSLocale* locale = [NSLocale localeWithLocaleIdentifier:localeID];
        block(locale, expectationsForLocale[localeID]);
    });
    // allow 1 sec per locale
    NSLog(@"Waiting %f seconds to run a test with %lu locales...", timeout, localeIdentifiers.count);
    [self waitForExpectationsWithTimeout:localeIdentifiers.count handler:nil];
}

@end
