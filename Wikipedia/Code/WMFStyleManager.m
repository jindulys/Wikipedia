
#import "WMFStyleManager.h"
#import "UIColor+WMFStyle.h"

static WMFStyleManager* _styleManager = nil;

@implementation WMFStyleManager

+ (void)setSharedStyleManager:(WMFStyleManager*)styleManger {
    _styleManager = styleManger;
}

- (void)applyStyleToWindow:(UIWindow*)window {
    window.backgroundColor = [UIColor whiteColor];
    [[UIButton appearance] setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    [[UIButton appearance] setBackgroundImage:[UIImage imageNamed:@"clear.png"] forState:UIControlStateNormal];
    [[UIButton appearance] setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [[UINavigationBar appearance] setBackIndicatorImage:[UIImage imageNamed:@"chevron-left"]];
    [[UINavigationBar appearance] setBackIndicatorTransitionMaskImage:[UIImage imageNamed:@"chevron-left"]];
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:0.305 green:0.305 blue:0.296 alpha:1]];
    [[UINavigationBar appearance] setTranslucent:NO];
    [[UITabBar appearance] setTranslucent:NO];
    [[UITabBar appearance] setTintColor:[UIColor wmf_blueTintColor]];
    [[UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil] setTintColor:[UIColor wmf_blueTintColor]];
}

@end


@implementation UIViewController (WMFStyleManager)

- (WMFStyleManager*)wmf_styleManager {
    return _styleManager;
}

@end

@implementation UIView (WMFStyleManager)

- (WMFStyleManager*)wmf_styleManager {
    return _styleManager;
}

@end
