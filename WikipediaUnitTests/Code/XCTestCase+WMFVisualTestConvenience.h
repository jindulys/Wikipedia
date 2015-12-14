//  Created by Monte Hurd on 8/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <XCTest/XCTest.h>

@interface XCTestCase (WMFVisualTestConvenience)

/**
 *  Get UILabel configured to 320 width and dynamic height based on length of text being shown.
 *  Useful for quick FBSnapshotTestCase test cases.
 *
 *  @param block This block is passed the label for easy configuration.
 *
 *  @return UILabel
 */
- (UILabel*)wmf_getLabelConfiguredWithBlock:(void (^)(UILabel*))block;

/**
 *  Get UITableViewCell configured to 320 width and dynamic height based on autolayout properties of its subviews.
 *  Useful for quick FBSnapshotTestCase test cases.
 *
 *  @param block This block is passed the cell for easy configuration.
 *
 *  @return UITableViewCell
 */
- (UITableViewCell*)wmf_getCellWithIdentifier:(NSString*)identifier
                                fromTableView:(UITableView*)tableView
                          configuredWithBlock:(void (^)(UITableViewCell*))block;

@end
