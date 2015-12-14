//
//  WMFNearbyArticleTableViewCell.m
//  Wikipedia
//
//  Created by Corey Floyd on 11/12/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFNearbyArticleTableViewCell.h"

@import CoreLocation;

#import "UIImageView+WMFImageFetching.h"

// Models
#import "WMFSearchResultDistanceProvider.h"
#import "WMFSearchResultBearingProvider.h"
#import "MWKTitle.h"

// Views
#import "WMFCompassView.h"

// Utils
#import "WMFMath.h"
#import "NSString+WMFDistance.h"
#import "UIColor+WMFStyle.h"
#import "UIFont+WMFStyle.h"
#import "UIImage+WMFStyle.h"
#import "UITableViewCell+SelectedBackground.h"
#import "UIImageView+WMFPlaceholder.h"

@interface WMFNearbyArticleTableViewCell ()

@property (strong, nonatomic) IBOutlet UIImageView* articleImageView;
@property (strong, nonatomic) IBOutlet WMFCompassView* compassView;
@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UIView* distanceLabelBackground;
@property (strong, nonatomic) IBOutlet UILabel* distanceLabel;

@property (strong, nonatomic) WMFSearchResultBearingProvider* bearingProvider;
@property (strong, nonatomic) WMFSearchResultDistanceProvider* distanceProvider;

@end

@implementation WMFNearbyArticleTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self configureImageViewWithPlaceholder];
    self.articleImageView.layer.cornerRadius        = self.articleImageView.bounds.size.width / 2;
    self.articleImageView.layer.borderWidth         = 1.0 / [UIScreen mainScreen].scale;
    self.articleImageView.layer.borderColor         = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
    self.distanceLabelBackground.layer.cornerRadius = 2.0;
    self.distanceLabelBackground.backgroundColor    = [UIColor wmf_nearbyDistanceBackgroundColor];
    self.distanceLabel.font                         = [UIFont wmf_nearbyDistanceFont];
    self.distanceLabel.textColor                    = [UIColor wmf_nearbyDistanceTextColor];
    [self wmf_addSelectedBackgroundView];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self configureImageViewWithPlaceholder];
    self.descriptionText    = nil;
    self.distanceProvider   = nil;
    self.bearingProvider    = nil;
    self.titleText          = nil;
    self.titleLabel.text    = nil;
    self.distanceLabel.text = nil;
}

- (void)configureImageViewWithPlaceholder {
    [self.articleImageView wmf_configureWithDefaultPlaceholder];
}

#pragma mark - Compass

- (void)setBearingProvider:(WMFSearchResultBearingProvider*)bearingProvider {
    [self.KVOController unobserve:_bearingProvider];
    _bearingProvider = bearingProvider;
    if (_bearingProvider) {
        self.compassView.hidden = NO;
        [self.KVOController observe:_bearingProvider
                            keyPath:WMF_SAFE_KEYPATH(_bearingProvider, bearingToLocation)
                            options:NSKeyValueObservingOptionInitial
                              block:^(WMFNearbyArticleTableViewCell* cell,
                                      WMFSearchResultBearingProvider* provider,
                                      NSDictionary* change) {
            [cell setBearing:provider.bearingToLocation];
        }];
    } else {
        self.compassView.hidden = YES;
    }
}

- (void)setBearing:(CLLocationDegrees)bearing {
    self.compassView.angleRadians = DEGREES_TO_RADIANS(bearing);
}

#pragma mark - Title/Description

- (void)setTitleText:(NSString*)titleText {
    if (WMF_EQUAL(_titleText, isEqualToString:, titleText)) {
        return;
    }
    _titleText = [titleText copy];
    [self updateTitleLabel];
}

- (void)setDescriptionText:(NSString*)descriptionText {
    if (WMF_EQUAL(_descriptionText, isEqualToString:, descriptionText)) {
        return;
    }
    _descriptionText = descriptionText;
    [self updateTitleLabel];
}

- (void)updateTitleLabel {
    NSMutableAttributedString* attributedTitleAndDescription = [NSMutableAttributedString new];

    NSAttributedString* titleText = [self attributedTitleText];
    if ([titleText length] > 0) {
        [attributedTitleAndDescription appendAttributedString:titleText];
    }

    NSAttributedString* searchResultDescription = [self attributedDescriptionText];
    if ([searchResultDescription length] > 0) {
        [attributedTitleAndDescription appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\n"]];
        [attributedTitleAndDescription appendAttributedString:searchResultDescription];
    }

    self.titleLabel.attributedText = attributedTitleAndDescription;
}

- (NSAttributedString*)attributedTitleText {
    if ([self.titleText length] == 0) {
        return nil;
    }

    return [[NSAttributedString alloc] initWithString:self.titleText attributes:@{
                NSFontAttributeName: [UIFont wmf_nearbyTitleFont],
                NSForegroundColorAttributeName: [UIColor wmf_nearbyTitleColor]
            }];
}

- (NSAttributedString*)attributedDescriptionText {
    if ([self.descriptionText length] == 0) {
        return nil;
    }

    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.paragraphSpacingBefore = 2.0;

    return [[NSAttributedString alloc] initWithString:self.descriptionText attributes:@{
                NSFontAttributeName: [UIFont wmf_nearbyDescriptionFont],
                NSForegroundColorAttributeName: [UIColor wmf_nearbyDescriptionColor],
                NSParagraphStyleAttributeName: paragraphStyle
            }];
}

#pragma mark - Distance

- (void)setDistanceProvider:(WMFSearchResultDistanceProvider*)distanceProvider {
    [self.KVOController unobserve:_distanceProvider];
    _distanceProvider = distanceProvider;
    if (_distanceProvider) {
        [self.KVOController observe:_distanceProvider
                            keyPath:WMF_SAFE_KEYPATH(_distanceProvider, distanceToUser)
                            options:NSKeyValueObservingOptionInitial
                              block:^(WMFNearbyArticleTableViewCell* cell,
                                      WMFSearchResultDistanceProvider* provider,
                                      NSDictionary* change) {
            [cell setDistance:provider.distanceToUser];
        }];
    } else {
        [self setDistance:0];
    }
}

- (void)setDistance:(CLLocationDistance)distance {
#if DEBUG && 0
    //   Set ^ to 1 to debug live distance updates by showing the full value
    self.distanceLabel.text = [NSString stringWithFormat:@"%f", distance];
#else
    self.distanceLabel.text = [NSString wmf_localizedStringForDistance:distance];
#endif
}

#pragma mark - Image

- (void)setImageURL:(NSURL*)imageURL {
    [self.articleImageView wmf_setImageWithURL:imageURL detectFaces:YES];
}

- (void)setImage:(MWKImage*)image {
    [self.articleImageView wmf_setImageWithMetadata:image detectFaces:YES];
}

@end
