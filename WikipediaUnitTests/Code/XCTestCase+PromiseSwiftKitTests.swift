//
//  XCTestCase+PromiseKitTests.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 11/20/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

import XCTest

let expectedFailureDescriptionPrefix =
"Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: \"testShouldNotFulfillExpectationWhenTimeoutExpires"

class XCTestCase_PromiseKitSwiftTests: XCTestCase {
    override func recordFailureWithDescription(
        description: String,
        inFile filePath: String,
        atLine lineNumber: UInt,
        expected: Bool) {
            if (!description.hasPrefix(expectedFailureDescriptionPrefix)) {
                // recorded failure wasn't the expected timeout
                super.recordFailureWithDescription(
                    "expected test description starting with <\(expectedFailureDescriptionPrefix)> but was <\(description)>",
                    inFile: filePath,
                    atLine: lineNumber,
                    expected: expected)
            }
    }

    func testShouldNotFulfillExpectationWhenTimeoutExpires() {
        var resolve: (() -> Void)!
        expectPromise(toResolve()) { () -> Promise<Void> in
            let (p, fulfill, _) = Promise<Void>.pendingPromise()
            resolve = fulfill
            return p
        }
        // Resolve after wait context, and which we should handle internally so it doesn't throw an assertion.
        resolve()
    }
}
