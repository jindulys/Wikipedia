//  Created by Monte Hurd on 8/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import "NSAttributedString+WMFTrim.h"
#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>
#import "FBSnapshotTestCase+WMFConvenience.h"

@interface NSAttributedString_WMFTrimTests : FBSnapshotTestCase

@end

@implementation NSAttributedString_WMFTrimTests

- (void)setUp {
    [super setUp];
    self.recordMode     = [[NSUserDefaults standardUserDefaults] wmf_visualTestBatchRecordMode];
    self.deviceAgnostic = YES;
}

- (NSAttributedString*)attrString {
    NSMutableAttributedString* attributedText = [[NSMutableAttributedString alloc] initWithString:@" \n \n This is a test string which should help confirm that this is working the way we want it to.  \n"];
    [attributedText addAttribute:NSBackgroundColorAttributeName value:[UIColor greenColor] range:[attributedText.string rangeOfString:@"should"]];
    [attributedText addAttribute:NSBackgroundColorAttributeName value:[UIColor greenColor] range:[attributedText.string rangeOfString:@"working"]];
    return attributedText;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testTrimReference {
    [self wmf_visuallyVerifyMultilineLabelWithText:[self attrString]];
}

- (void)testTrim {
    [self wmf_visuallyVerifyMultilineLabelWithText:[[self attrString] wmf_trim]];
}

- (void)testAllWhiteSpaceString {
    assertThat([[[NSMutableAttributedString alloc] initWithString:@"\n \n   \n   "] wmf_trim].string, is(equalTo(@"")));
}

- (void)testTrailingWhiteSpaceString {
    assertThat([[[NSMutableAttributedString alloc] initWithString:@"test text  \n   "] wmf_trim].string, is(equalTo(@"test text")));
}

- (void)testLeadingWhiteSpaceString {
    assertThat([[[NSMutableAttributedString alloc] initWithString:@"\n \n  test text"] wmf_trim].string, is(equalTo(@"test text")));
}

@end
