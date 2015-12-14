//
//  WMFPicOfTheDayTableViewCell.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/23/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFPicOfTheDayTableViewCell_Testing.h"
#import "UIImageView+WMFPlaceholder.h"
#import "UIImageView+WMFImageFetchingInternal.h"
#import "WMFGradientView.h"

@interface WMFPicOfTheDayTableViewCell ()

@property (weak, nonatomic) IBOutlet WMFGradientView* displayTitleBackgroundView;

@property (nonatomic, strong) IBOutlet UILabel* displayTitleLabel;

@end

@implementation WMFPicOfTheDayTableViewCell

- (void)dealloc {
    // This is guaranteed to be called before dealloc, since observation starts in -awakeFromNib
    [self.KVOControllerNonRetaining unobserve:self.potdImageView];
}

- (void)setDisplayTitle:(NSString*)displayTitle {
    self.displayTitleLabel.text = displayTitle;
}

- (void)setImageURL:(NSURL*)imageURL {
    [self.potdImageView wmf_setImageWithURL:imageURL detectFaces:YES];
}

#pragma mark - UITableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.potdImageView wmf_configureWithDefaultPlaceholder];
    [self.KVOControllerNonRetaining observe:self.potdImageView
                                    keyPath:WMF_SAFE_KEYPATH(self.potdImageView, image)
                                    options:NSKeyValueObservingOptionInitial
                                      block:^(WMFPicOfTheDayTableViewCell* cell,
                                              UIImageView* potdImageView,
                                              NSDictionary* change) {
        BOOL didSetDesiredImage = [potdImageView wmf_imageURLToFetch] != nil;
        // whether or not these properties are animated will be determined based on whether or not
        // there was an animation setup when image was set
        cell.displayTitleLabel.alpha = didSetDesiredImage ? 1.0 : 0.0;
        cell.displayTitleBackgroundView.alpha = cell.displayTitleLabel.alpha;
    }];
}

- (void)prepareForReuse {
    [super awakeFromNib];
    self.displayTitleLabel.text = @"";
    [self.potdImageView wmf_configureWithDefaultPlaceholder];
}

@end
