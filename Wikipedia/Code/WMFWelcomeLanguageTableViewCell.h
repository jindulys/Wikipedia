//
//  WMFWelcomeLanguageTableViewCell.h
//  Wikipedia
//
//  Created by Corey Floyd on 11/24/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MGSwipeTableCell;

@interface WMFWelcomeLanguageTableViewCell : MGSwipeTableCell

@property (strong, nonatomic) IBOutlet UILabel* numberLabel;
@property (strong, nonatomic) IBOutlet UILabel* languageNameLabel;

@property (copy, nonatomic) dispatch_block_t deleteButtonTapped;

@end
