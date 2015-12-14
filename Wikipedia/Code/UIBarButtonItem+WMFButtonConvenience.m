//  Created by Monte Hurd on 6/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIBarButtonItem+WMFButtonConvenience.h"

@implementation UIBarButtonItem (WMFButtonConvenience)

+ (UIBarButtonItem*)wmf_buttonType:(WMFButtonType)type
                           handler:(void (^ __nullable)(id sender))action {
    UIButton* button      = [UIButton wmf_buttonType:type handler:action];
    UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithCustomView:button];
    item.width = button.intrinsicContentSize.width;
    return item;
}

- (UIButton*)wmf_UIButton {
    return [self.customView isKindOfClass:[UIButton class]] ? (UIButton*)self.customView : nil;
}

+ (UIBarButtonItem*)wmf_barButtonItemOfFixedWidth:(CGFloat)width {
    UIBarButtonItem* item =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    item.width = width;
    return item;
}

@end
