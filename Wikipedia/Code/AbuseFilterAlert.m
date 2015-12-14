//  Created by Monte Hurd on 7/21/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "AbuseFilterAlert.h"
#import "PaddedLabel.h"
#import "Defines.h"
#import "WikiGlyphLabel.h"
#import "WikiGlyph_Chars.h"
#import "WMF_Colors.h"
#import "WikipediaAppUtils.h"
#import "BulletedLabel.h"

typedef NS_ENUM (NSInteger, ViewType) {
    VIEW_TYPE_ICON,
    VIEW_TYPE_HEADING,
    VIEW_TYPE_SUBHEADING,
    VIEW_TYPE_ITEM
};

@interface AbuseFilterAlert ()

@property (nonatomic, strong) NSMutableArray* subViews;

@property (nonatomic, strong) NSMutableArray* subViewData;

@end

@implementation AbuseFilterAlert

- (id)initWithType:(AbuseFilterAlertType)alertType {
    self = [super init];
    if (self) {
        self.subViews                                  = @[].mutableCopy;
        self.subViewData                               = @[].mutableCopy;
        self.backgroundColor                           = [UIColor whiteColor];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self addTopMask];
        _alertType = alertType;
        [self setupSubViewData];
        [self makeSubViews];
        self.minSubviewHeight = 0;
        [self setTabularSubviews:self.subViews];

        // Add just a bit of scrolling margin to bottom just in case the bottom of the last
        // items is near the bottom of the screen.
        self.contentInset = UIEdgeInsetsMake(0, 0, 50, 0);
    }
    return self;
}

- (void)addTopMask {
    // Prevents white bar from appearing above the icon view if user pulls down.
    UIView* topMask = [[UIView alloc] init];
    topMask.backgroundColor                           = CHROME_COLOR;
    topMask.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:topMask];

    NSDictionary* views = @{@"topMask": topMask};

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[topMask]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:topMask
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1
                                                      constant:-1000]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:topMask
                                                     attribute:NSLayoutAttributeBottom
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1
                                                      constant:0]];
}

- (void)setupSubViewData {
    [self.subViewData addObject:
     @{
         @"type": @(VIEW_TYPE_ICON),
         @"string": ((self.alertType == ABUSE_FILTER_DISALLOW) ? WIKIGLYPH_X : WIKIGLYPH_FLAG),
         @"backgroundColor": ((self.alertType == ABUSE_FILTER_DISALLOW) ? WMF_COLOR_RED : WMF_COLOR_ORANGE),
         @"fontColor": [UIColor whiteColor],
         @"baselineOffset": @((self.alertType == ABUSE_FILTER_DISALLOW) ? 8.4 : 5.5)
     }.mutableCopy
    ];

    UIColor* grayColor = UIColorFromRGBWithAlpha(0x999999, 1.0);

    switch (self.alertType) {
        case ABUSE_FILTER_WARNING:

            [self.subViewData addObjectsFromArray:
             @[
                 @{
                     @"type": @(VIEW_TYPE_HEADING),
                     @"string": MWLocalizedString(@"abuse-filter-warning-heading", nil),
                     @"backgroundColor": [UIColor whiteColor],
                     @"fontColor": [UIColor darkGrayColor]
                 }.mutableCopy,
                 @{
                     @"type": @(VIEW_TYPE_SUBHEADING),
                     @"string": MWLocalizedString(@"abuse-filter-warning-subheading", nil),
                     @"backgroundColor": [UIColor whiteColor],
                     @"fontColor": grayColor
                 }.mutableCopy,
                 @{
                     @"type": @(VIEW_TYPE_ITEM),
                     @"string": MWLocalizedString(@"abuse-filter-warning-caps", nil),
                     @"backgroundColor": [UIColor whiteColor],
                     @"fontColor": grayColor
                 }.mutableCopy,
                 @{
                     @"type": @(VIEW_TYPE_ITEM),
                     @"string": MWLocalizedString(@"abuse-filter-warning-blanking", nil),
                     @"backgroundColor": [UIColor whiteColor],
                     @"fontColor": grayColor
                 }.mutableCopy,
                 @{
                     @"type": @(VIEW_TYPE_ITEM),
                     @"string": MWLocalizedString(@"abuse-filter-warning-irrelevant", nil),
                     @"backgroundColor": [UIColor whiteColor],
                     @"fontColor": grayColor
                 }.mutableCopy,
                 @{
                     @"type": @(VIEW_TYPE_ITEM),
                     @"string": MWLocalizedString(@"abuse-filter-warning-repeat", nil),
                     @"backgroundColor": [UIColor whiteColor],
                     @"fontColor": grayColor
                 }.mutableCopy
             ]];

            break;
        case ABUSE_FILTER_DISALLOW:

            [self.subViewData addObjectsFromArray:
             @[
                 @{
                     @"type": @(VIEW_TYPE_HEADING),
                     @"string": MWLocalizedString(@"abuse-filter-disallow-heading", nil),
                     @"backgroundColor": [UIColor whiteColor],
                     @"fontColor": [UIColor darkGrayColor]
                 }.mutableCopy,
                 @{
                     @"type": @(VIEW_TYPE_ITEM),
                     @"string": MWLocalizedString(@"abuse-filter-disallow-unconstructive", nil),
                     @"backgroundColor": [UIColor whiteColor],
                     @"fontColor": grayColor
                 }.mutableCopy,
                 @{
                     @"type": @(VIEW_TYPE_ITEM),
                     @"string": MWLocalizedString(@"abuse-filter-disallow-notable", nil),
                     @"backgroundColor": [UIColor whiteColor],
                     @"fontColor": grayColor
                 }.mutableCopy
             ]];

            break;
        default:
            break;
    }

    for (NSMutableDictionary* viewData in self.subViewData) {
        NSNumber* type = viewData[@"type"];
        switch (type.integerValue) {
            case VIEW_TYPE_ICON:
                viewData[@"topPadding"]    = @0;
                viewData[@"bottomPadding"] = @0;
                viewData[@"leftPadding"]   = @0;
                viewData[@"rightPadding"]  = @0;
                viewData[@"fontSize"]      = @((self.alertType == ABUSE_FILTER_DISALLOW) ? (74.0 * MENUS_SCALE_MULTIPLIER) : (70.0 * MENUS_SCALE_MULTIPLIER));
                break;
            case VIEW_TYPE_HEADING:
                viewData[@"topPadding"]    = @35;
                viewData[@"bottomPadding"] = @15;
                viewData[@"leftPadding"]   = @20;
                viewData[@"rightPadding"]  = @20;
                viewData[@"lineSpacing"]   = @3;
                viewData[@"kearning"]      = @0.4;
                viewData[@"font"]          = [UIFont boldSystemFontOfSize:23.0 * MENUS_SCALE_MULTIPLIER];
                break;
            case VIEW_TYPE_SUBHEADING:
                viewData[@"topPadding"]    = @0;
                viewData[@"bottomPadding"] = @8;
                viewData[@"leftPadding"]   = @20;
                viewData[@"rightPadding"]  = @20;
                viewData[@"lineSpacing"]   = @2;
                viewData[@"kearning"]      = @0;
                viewData[@"font"]          = [UIFont systemFontOfSize:16.0 * MENUS_SCALE_MULTIPLIER];
                break;
            case VIEW_TYPE_ITEM:
                viewData[@"topPadding"]    = @0;
                viewData[@"bottomPadding"] = (self.alertType == ABUSE_FILTER_WARNING) ? @8 : @15;
                viewData[@"leftPadding"]   = (self.alertType == ABUSE_FILTER_WARNING) ? @30 : @20;
                viewData[@"rightPadding"]  = @20;
                viewData[@"lineSpacing"]   = @6;
                viewData[@"kearning"]      = @0;
                viewData[@"bulletType"]    = (self.alertType == ABUSE_FILTER_WARNING) ? @(BULLET_TYPE_ROUND) : @(BULLET_TYPE_NONE);
                viewData[@"font"]          = [UIFont systemFontOfSize:16.0 * MENUS_SCALE_MULTIPLIER];
                break;
            default:
                break;
        }
    }
}

- (void)makeSubViews {
    UINib* bulletedLabelNib = [UINib nibWithNibName:@"BulletedLabel" bundle:nil];

    for (NSDictionary* viewData in self.subViewData) {
        NSNumber* type = viewData[@"type"];
        switch (type.integerValue) {
            case VIEW_TYPE_ICON:
            {
                UIView* view = [[UIView alloc] init];
                view.backgroundColor = CHROME_COLOR;

                WikiGlyphLabel* label = [[WikiGlyphLabel alloc] init];
                label.translatesAutoresizingMaskIntoConstraints = NO;
                label.textAlignment                             = NSTextAlignmentCenter;

                label.backgroundColor = viewData[@"backgroundColor"];
                NSNumber* fontSize       = viewData[@"fontSize"];
                NSNumber* baselineOffset = viewData[@"baselineOffset"];

                [label setWikiText:viewData[@"string"]
                             color:viewData[@"fontColor"]
                              size:fontSize.floatValue
                    baselineOffset:baselineOffset.floatValue];

                CGFloat iconHeight   = 78.0 * MENUS_SCALE_MULTIPLIER;
                CGFloat topBarHeight = 125.0 * MENUS_SCALE_MULTIPLIER;
                label.layer.cornerRadius = iconHeight / 2.0;
                label.clipsToBounds      = YES;

                [view addSubview:label];

                NSDictionary* views   = @{@"label": label, @"v1": view};
                NSDictionary* metrics = @{
                    @"iconHeight": @(iconHeight),
                    @"topBarHeight": @(topBarHeight)
                };

                [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[v1(topBarHeight)]"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];

                [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label(iconHeight)]"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];

                [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[label(iconHeight)]"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];

                [view addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                                 attribute:NSLayoutAttributeCenterX
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:view
                                                                 attribute:NSLayoutAttributeCenterX
                                                                multiplier:1
                                                                  constant:0]];

                [view addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:view
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1
                                                                  constant:0]];
                [self.subViews addObject:view];
            }
            break;
            default:
            {
                BulletedLabel* item =
                    [[bulletedLabelNib instantiateWithOwner:self options:nil] firstObject];

                item.translatesAutoresizingMaskIntoConstraints = NO;
                item.backgroundColor                           = viewData[@"backgroundColor"];

                NSNumber* topPadding    = viewData[@"topPadding"];
                NSNumber* bottomPadding = viewData[@"bottomPadding"];
                NSNumber* leftPadding   = viewData[@"leftPadding"];
                NSNumber* rightPadding  = viewData[@"rightPadding"];

                NSNumber* bulletType = [viewData objectForKey:@"bulletType"];
                if (bulletType) {
                    item.bulletType = bulletType.integerValue;

                    // Use same top and left padding.
                    item.bulletLabel.padding = UIEdgeInsetsMake(topPadding.floatValue, leftPadding.floatValue, 0, 4);

                    // Zero out left padding because we already have the left padding applied
                    // to the prefixLabel so no longer need it for the titleLabel.
                    leftPadding = @0;

                    UIColor* color = viewData[@"fontColor"];
                    item.bulletColor = color;
                }

                item.titleLabel.padding = UIEdgeInsetsMake(topPadding.floatValue, leftPadding.floatValue, bottomPadding.floatValue, rightPadding.floatValue);

                [self setText:MWLocalizedString(viewData[@"string"], nil) forLabel:item.titleLabel subViewData:viewData];

                [self.subViews addObject:item];
            }
            break;
        }
    }
}

- (void)setText:(NSString*)text forLabel:(UILabel*)label subViewData:(NSDictionary*)viewData {
    UIFont* font          = viewData[@"font"];
    NSNumber* kearning    = viewData[@"kearning"];
    NSNumber* lineSpacing = viewData[@"lineSpacing"];
    UIColor* color        = viewData[@"fontColor"];

    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = lineSpacing.floatValue;

    NSDictionary* attributes =
        @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: color,
        NSKernAttributeName: kearning,
        NSParagraphStyleAttributeName: paragraphStyle
    };

    label.attributedText =
        [[NSAttributedString alloc] initWithString:text
                                        attributes:attributes];
}

@end
