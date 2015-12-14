
#import "WMFWelcomeViewController.h"
#import "WMFWelcomeIntroductionViewController.h"
#import "WMFBoringNavigationTransition.h"

@interface WMFWelcomeViewController ()<UINavigationControllerDelegate>

@property (nonatomic, strong) UINavigationController* welcomeNavigationController;

@end

@implementation WMFWelcomeViewController

+ (instancetype)welcomeViewControllerFromDefaultStoryBoard {
    return [[UIStoryboard storyboardWithName:@"WMFWelcome" bundle:nil] instantiateInitialViewController];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[UINavigationController class]]) {
        self.welcomeNavigationController          = segue.destinationViewController;
        self.welcomeNavigationController.delegate = self;
    }
}

- (IBAction)dismiss:(id)sender {
    if (self.completionBlock) {
        self.completionBlock();
    }
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController*)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController*)fromVC
                                                 toViewController:(UIViewController*)toVC {
    WMFBoringNavigationTransition* animation = [[WMFBoringNavigationTransition alloc] init];
    animation.operation = operation;
    return animation;
}

@end
