#import "WMFArticleContainerViewController_Private.h"
#import "Wikipedia-Swift.h"

// Frameworks
#import <Masonry/Masonry.h>
#import <BlocksKit/BlocksKit+UIKit.h>

// Controller
#import "WebViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "WMFSaveButtonController.h"
#import "WMFArticleContainerViewController_Transitioning.h"
#import "WMFArticleHeaderImageGalleryViewController.h"
#import "WMFRelatedTitleListDataSource.h"
#import "WMFArticleListTableViewController.h"
#import "UITabBarController+WMFExtensions.h"
#import "WMFShareOptionsController.h"
#import "WMFModalImageGalleryViewController.h"
#import "UIViewController+WMFSearchButton.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "SectionEditorViewController.h"
#import "LanguagesViewController.h"
#import "MWKLanguageLinkController.h"

//Funnel
#import "WMFShareFunnel.h"
#import "ProtectedEditAttemptFunnel.h"


// Model
#import "MWKDataStore.h"
#import "MWKArticle+WMFAnalyticsLogging.h"
#import "MWKCitation.h"
#import "MWKTitle.h"
#import "MWKSavedPageList.h"
#import "MWKUserDataStore.h"
#import "MWKArticle+WMFSharing.h"
#import "MWKArticlePreview.h"
#import "MWKHistoryList.h"
#import "MWKProtectionStatus.h"
#import "MWKSectionList.h"
#import "MWKLanguageLink.h"
#import "MWKHistoryList.h"
#import "WMFRelatedSearchResults.h"

// Networking
#import "WMFArticleFetcher.h"

// View
#import "UIViewController+WMFEmptyView.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "UIScrollView+WMFContentOffsetUtils.h"
#import "UIWebView+WMFTrackingView.h"
#import "NSArray+WMFLayoutDirectionUtilities.h"
#import "UIViewController+WMFOpenExternalUrl.h"

#import "NSString+WMFPageUtilities.h"
#import "NSURL+WMFLinkParsing.h"
#import "NSURL+Extras.h"

@import SafariServices;

@import JavaScriptCore;

@import Tweaks;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleContainerViewController ()
<WMFWebViewControllerDelegate,
 UINavigationControllerDelegate,
 WMFArticleHeaderImageGalleryViewControllerDelegate,
 WMFImageGalleryViewControllerDelegate,
 WMFSearchPresentationDelegate,
 SectionEditorViewControllerDelegate,
 UIViewControllerPreviewingDelegate,
 LanguageSelectionDelegate>

@property (nonatomic, strong, readwrite) MWKTitle* articleTitle;
@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;
@property (nonatomic, assign, readwrite) MWKHistoryDiscoveryMethod discoveryMethod;

// Data
@property (nonatomic, strong, readonly) MWKHistoryEntry* historyEntry;
@property (nonatomic, strong, readonly) MWKSavedPageList* savedPages;
@property (nonatomic, strong, readonly) MWKHistoryList* recentPages;

@property (nonatomic, strong) WMFRelatedTitleListDataSource* readMoreDataSource;

// Fetchers
@property (nonatomic, strong, null_resettable) WMFArticleFetcher* articleFetcher;
@property (nonatomic, strong, nullable) AnyPromise* articleFetcherPromise;

// Children
@property (nonatomic, strong) WMFArticleHeaderImageGalleryViewController* headerGallery;
@property (nonatomic, strong) WMFArticleListTableViewController* readMoreListViewController;
@property (nonatomic, strong) WMFSaveButtonController* saveButtonController;

// Logging
@property (strong, nonatomic, nullable) WMFShareFunnel* shareFunnel;
@property (strong, nonatomic, nullable) WMFShareOptionsController* shareOptionsController;

// Views
@property (nonatomic, strong) MASConstraint* headerHeightConstraint;
@property (nonatomic, strong) UIBarButtonItem* refreshToolbarItem;
@property (nonatomic, strong) UIBarButtonItem* saveToolbarItem;
@property (nonatomic, strong) UIBarButtonItem* languagesToolbarItem;
@property (nonatomic, strong) UIBarButtonItem* shareToolbarItem;
@property (nonatomic, strong) UIBarButtonItem* tableOfContentsToolbarItem;
@property (strong, nonatomic) UIProgressView* progressView;

@property (strong, nonatomic, nullable) NSTimer* significantlyViewedTimer;

// Previewing
@property (nonatomic, weak) id<UIViewControllerPreviewing> linkPreviewingContext;

/**
 *  Need to track this so we don't update the progress bar when loading cached articles
 */
@property (nonatomic, assign) BOOL webViewIsLoadingFetchedArticle;

/**
 *  Need to track this so we can display the empty view reliably
 */
@property (nonatomic, assign) BOOL articleFetchWasAttempted;

@end

@implementation WMFArticleContainerViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           dataStore:(MWKDataStore*)dataStore
                     discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    NSParameterAssert(title);
    NSParameterAssert(dataStore);

    self = [super init];
    if (self) {
        self.articleTitle    = title;
        self.dataStore       = dataStore;
        self.discoveryMethod = discoveryMethod;
        [self observeArticleUpdates];
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

#pragma mark - Article languages

- (void)showLanguagePicker {
    LanguagesViewController* languagesVC = [LanguagesViewController wmf_initialViewControllerFromClassStoryboard];
    languagesVC.articleTitle              = self.articleTitle;
    languagesVC.languageSelectionDelegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:languagesVC] animated:YES completion:nil];
}

- (void)languagesController:(LanguagesViewController*)controller didSelectLanguage:(MWKLanguageLink*)language {
    [[MWKLanguageLinkController sharedInstance] addPreferredLanguage:language];
    [self dismissViewControllerAnimated:YES completion:^{
        [self wmf_pushArticleViewControllerWithTitle:language.title discoveryMethod:MWKHistoryDiscoveryMethodLink dataStore:self.dataStore];
    }];
}

#pragma mark - Accessors

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ %@", [super description], self.articleTitle];
}

- (void)setArticle:(nullable MWKArticle*)article {
    if (_article == article) {
        return;
    }

    _tableOfContentsViewController = nil;
    _shareFunnel                   = nil;
    _shareOptionsController        = nil;
    [self.articleFetcher cancelFetchForPageTitle:_articleTitle];

    _article                       = article;
    self.webViewController.article = _article;
    [self.headerGallery showImagesInArticle:_article];

    [self setupToolbar];
    [self createTableOfContentsViewController];
    [self startSignificantlyViewedTimer];
    if (article) {
        [self wmf_hideEmptyView];
    }
}

- (MWKHistoryList*)recentPages {
    return self.dataStore.userDataStore.historyList;
}

- (MWKSavedPageList*)savedPages {
    return self.dataStore.userDataStore.savedPageList;
}

- (MWKHistoryEntry*)historyEntry {
    return [self.recentPages entryForTitle:self.articleTitle];
}

- (WMFRelatedTitleListDataSource*)readMoreDataSource {
    if (!_readMoreDataSource) {
        _readMoreDataSource =
            [[WMFRelatedTitleListDataSource alloc] initWithTitle:self.articleTitle
                                                       dataStore:self.dataStore
                                                   savedPageList:self.savedPages
                                                     resultLimit:3];
    }
    return _readMoreDataSource;
}

- (WMFArticleListTableViewController*)readMoreListViewController {
    if (!_readMoreListViewController) {
        _readMoreListViewController            = [[WMFSelfSizingArticleListTableViewController alloc] init];
        _readMoreListViewController.dataStore  = self.dataStore;
        _readMoreListViewController.dataSource = self.readMoreDataSource;
    }
    return _readMoreListViewController;
}

- (WMFArticleFetcher*)articleFetcher {
    if (!_articleFetcher) {
        _articleFetcher = [[WMFArticleFetcher alloc] initWithDataStore:self.dataStore];
    }
    return _articleFetcher;
}

- (WebViewController*)webViewController {
    if (!_webViewController) {
        _webViewController                      = [WebViewController wmf_initialViewControllerFromClassStoryboard];
        _webViewController.delegate             = self;
        _webViewController.headerViewController = self.headerGallery;
    }
    return _webViewController;
}

- (WMFArticleHeaderImageGalleryViewController*)headerGallery {
    if (!_headerGallery) {
        _headerGallery          = [[WMFArticleHeaderImageGalleryViewController alloc] init];
        _headerGallery.delegate = self;
    }
    return _headerGallery;
}

- (nullable WMFShareFunnel*)shareFunnel {
    NSParameterAssert(self.article);
    if (!self.article) {
        return nil;
    }
    if (!_shareFunnel) {
        _shareFunnel = [[WMFShareFunnel alloc] initWithArticle:self.article];
    }
    return _shareFunnel;
}

- (nullable WMFShareOptionsController*)shareOptionsController {
    NSParameterAssert(self.article);
    if (!self.article) {
        return nil;
    }
    if (!_shareOptionsController) {
        _shareOptionsController = [[WMFShareOptionsController alloc] initWithArticle:self.article
                                                                         shareFunnel:self.shareFunnel];
    }
    return _shareOptionsController;
}

- (UIProgressView*)progressView {
    if (!_progressView) {
        UIProgressView* progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        progress.translatesAutoresizingMaskIntoConstraints = NO;
        progress.trackTintColor                            = [UIColor clearColor];
        progress.tintColor                                 = [UIColor wmf_blueTintColor];
        _progressView                                      = progress;
    }

    return _progressView;
}

#pragma mark - Notifications and Observations

- (void)applicationWillResignActiveWithNotification:(NSNotification*)note {
    [self saveWebViewScrollOffset];
}

- (void)articleUpdatedWithNotification:(NSNotification*)note {
    MWKArticle* article = note.userInfo[MWKArticleKey];
    if ([self.articleTitle isEqualToTitle:article.title]) {
        self.article = article;
    }
}

- (void)observeArticleUpdates {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MWKArticleSavedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(articleUpdatedWithNotification:)
                                                 name:MWKArticleSavedNotification
                                               object:nil];
}

- (void)unobserveArticleUpdates {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MWKArticleSavedNotification object:nil];
}

#pragma mark - Toolbar Setup

- (void)setupToolbar {
    [self updateToolbarItemsIfNeeded];
    [self updateToolbarItemEnabledState];
}

- (void)updateToolbarItemsIfNeeded {
    if (!self.saveButtonController) {
        self.saveButtonController = [[WMFSaveButtonController alloc] initWithBarButtonItem:self.saveToolbarItem savedPageList:self.savedPages title:self.articleTitle];
    }

    NSArray<UIBarButtonItem*>* toolbarItems =
        [NSArray arrayWithObjects:
         self.refreshToolbarItem, [self flexibleSpaceToolbarItem],
         self.shareToolbarItem, [UIBarButtonItem wmf_barButtonItemOfFixedWidth:24.f],
         self.saveToolbarItem, [UIBarButtonItem wmf_barButtonItemOfFixedWidth:18.f],
         self.languagesToolbarItem,
         [self flexibleSpaceToolbarItem],
         self.tableOfContentsToolbarItem,
         nil];

    if (self.toolbarItems.count != toolbarItems.count) {
        // HAX: only update toolbar if # of items has changed, otherwise items will (somehow) get lost
        [self setToolbarItems:toolbarItems animated:YES];
    }
}

- (void)updateToolbarItemEnabledState {
    self.refreshToolbarItem.enabled         = self.article != nil;
    self.shareToolbarItem.enabled           = self.article != nil;
    self.languagesToolbarItem.enabled       = self.article.languagecount > 1;
    self.tableOfContentsToolbarItem.enabled = self.article != nil && !self.article.isMain;
}

#pragma mark - Toolbar Items

- (UIBarButtonItem*)tableOfContentsToolbarItem {
    if (!_tableOfContentsToolbarItem) {
        _tableOfContentsToolbarItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toc"]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(didTapTableOfContentsButton:)];
        return _tableOfContentsToolbarItem;
    }
    return _tableOfContentsToolbarItem;
}

- (UIBarButtonItem*)saveToolbarItem {
    if (!_saveToolbarItem) {
        _saveToolbarItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"save"] style:UIBarButtonItemStylePlain target:nil action:nil];
    }
    return _saveToolbarItem;
}

- (UIBarButtonItem*)refreshToolbarItem {
    if (!_refreshToolbarItem) {
        _refreshToolbarItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"refresh"] style:UIBarButtonItemStylePlain target:self action:@selector(fetchArticle)];
    }
    return _refreshToolbarItem;
}

- (UIBarButtonItem*)flexibleSpaceToolbarItem {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                         target:nil
                                                         action:NULL];
}

- (UIBarButtonItem*)shareToolbarItem {
    if (!_shareToolbarItem) {
        @weakify(self);
        _shareToolbarItem = [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                            handler:^(id sender){
            @strongify(self);
            [self shareArticleWithTextSnippet:[self.webViewController selectedText] fromButton:sender];
        }];
    }
    return _shareToolbarItem;
}

- (UIBarButtonItem*)languagesToolbarItem {
    if (!_languagesToolbarItem) {
        _languagesToolbarItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"language"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(showLanguagePicker)];
    }
    return _languagesToolbarItem;
}

#pragma mark - Progress

- (void)addProgressView {
    [self.view addSubview:self.progressView];
    [self.progressView mas_makeConstraints:^(MASConstraintMaker* make) {
        make.top.equalTo(self.progressView.superview.mas_top);
        make.left.equalTo(self.progressView.superview.mas_left);
        make.right.equalTo(self.progressView.superview.mas_right);
        make.height.equalTo(@2.0);
    }];
}

- (void)removeProgressView {
    [self.progressView removeFromSuperview];
}

- (void)showProgressViewAnimated:(BOOL)animated {
    self.progressView.progress = 0.05;

    if (!animated) {
        [self _showProgressView];
        return;
    }

    [UIView animateWithDuration:0.25 animations:^{
        [self _showProgressView];
    } completion:^(BOOL finished) {
    }];
}

- (void)_showProgressView {
    self.progressView.alpha = 1.0;
}

- (void)hideProgressViewAnimated:(BOOL)animated {
    //Don't remove the progress immediately, let the user see it then dismiss
    dispatchOnMainQueueAfterDelayInSeconds(0.5, ^{
        if (!animated) {
            [self _hideProgressView];
            return;
        }

        [UIView animateWithDuration:0.25 animations:^{
            [self _hideProgressView];
        } completion:nil];
    });
}

- (void)_hideProgressView {
    self.progressView.alpha = 0.0;
}

- (void)updateProgress:(CGFloat)progress animated:(BOOL)animated {
    if (progress < self.progressView.progress) {
        return;
    }
    [self.progressView setProgress:progress animated:animated];
}

/**
 *  Some of the progress is in loading the HTML into the webview
 *  This leaves 20% of progress for that work.
 */
- (CGFloat)totalProgressWithArticleFetcherProgress:(CGFloat)progress {
    return 0.8 * progress;
}

#pragma mark - Significantly Viewed Timer

- (void)startSignificantlyViewedTimer {
    if (self.significantlyViewedTimer) {
        return;
    }
    if (!self.article) {
        return;
    }
    MWKHistoryList* historyList = self.dataStore.userDataStore.historyList;
    MWKHistoryEntry* entry      = [historyList entryForTitle:self.articleTitle];
    if (!entry.titleWasSignificantlyViewed) {
        self.significantlyViewedTimer = [NSTimer scheduledTimerWithTimeInterval:FBTweakValue(@"Home", @"Related items", @"Required viewing time", 30.0) target:self selector:@selector(significantlyViewedTimerFired:) userInfo:nil repeats:NO];
    }
}

- (void)significantlyViewedTimerFired:(NSTimer*)timer {
    [self stopSignificantlyViewedTimer];
    MWKHistoryList* historyList = self.dataStore.userDataStore.historyList;
    [historyList setSignificantlyViewedOnPageInHistoryWithTitle:self.articleTitle];
    [historyList save];
}

- (void)stopSignificantlyViewedTimer {
    [self.significantlyViewedTimer invalidate];
    self.significantlyViewedTimer = nil;
}

#pragma mark - ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupToolbar];
    self.navigationItem.rightBarButtonItem = [self wmf_searchBarButtonItemWithDelegate:self];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveWithNotification:) name:UIApplicationWillResignActiveNotification object:nil];

    [self setupWebView];

    self.article = [self.dataStore existingArticleWithTitle:self.articleTitle];
    [self fetchArticle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self registerForPreviewingIfAvailable];
    [self startSignificantlyViewedTimer];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self addProgressView];
    [[NSUserDefaults standardUserDefaults] wmf_setOpenArticleTitle:self.articleTitle];
    if (!self.article && self.articleFetchWasAttempted) {
        [self wmf_showEmptyViewOfType:WMFEmptyViewTypeArticleDidNotLoad];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self stopSignificantlyViewedTimer];
    [self saveWebViewScrollOffset];
    [self removeProgressView];
    [super viewWillDisappear:animated];
    [[NSUserDefaults standardUserDefaults] wmf_setOpenArticleTitle:nil];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection*)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self registerForPreviewingIfAvailable];
}

#pragma mark - Web View Setup

- (void)setupWebView {
    [self addChildViewController:self.webViewController];
    [self.view addSubview:self.webViewController.view];
    [self.webViewController.view mas_makeConstraints:^(MASConstraintMaker* make) {
        make.leading.trailing.top.and.bottom.equalTo(self.view);
    }];
    [self.webViewController didMoveToParentViewController:self];
}

#pragma mark - Save Offset

- (void)saveWebViewScrollOffset {
    // Don't record scroll position of "main" pages.
    if (self.article.isMain) {
        return;
    }
    CGFloat offset = [self.webViewController currentVerticalOffset];
    if (offset > 0) {
        [self.recentPages setPageScrollPosition:offset onPageInHistoryWithTitle:self.articleTitle];
        [self.recentPages save];
    }
}

#pragma mark - Article Fetching

- (void)fetchArticle {
    @weakify(self);
    [self unobserveArticleUpdates];
    [self showProgressViewAnimated:YES];
    [self wmf_hideEmptyView];
    self.articleFetcherPromise = [self.articleFetcher fetchArticleForPageTitle:self.articleTitle progress:^(CGFloat progress) {
        [self updateProgress:[self totalProgressWithArticleFetcherProgress:progress] animated:YES];
    }].then(^(MWKArticle* article) {
        @strongify(self);
        [self saveWebViewScrollOffset];
        [self updateProgress:[self totalProgressWithArticleFetcherProgress:1.0] animated:YES];
        self.webViewIsLoadingFetchedArticle = YES;
        self.article = article;
        if (!self.article.isMain) {
            [self fetchReadMore];
        }
    }).catch(^(NSError* error){
        @strongify(self);
        [self hideProgressViewAnimated:YES];
        if (!self.article && self.view.superview) {
            dispatchOnMainQueueAfterDelayInSeconds(0.5, ^{
                //This can potentially fire after viewWillAppear, but before viewDidAppear.
                //In that case it animates strnagely, delay showing this just in case.
                [self wmf_showEmptyViewOfType:WMFEmptyViewTypeArticleDidNotLoad];
            });
        }
        if (!self.presentingViewController) {
            // only do error handling if not presenting gallery

            if (self.discoveryMethod == MWKHistoryDiscoveryMethodSaved && [self.article isCached]) {
                return;
            }

            [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];

            DDLogError(@"Article Fetch Error: %@", [error localizedDescription]);
        }
    }).finally(^{
        @strongify(self);
        self.articleFetcherPromise = nil;
        self.articleFetchWasAttempted = YES;
        [self observeArticleUpdates];
    });
}

- (void)fetchReadMore {
    @weakify(self);
    [self.readMoreDataSource fetch]
    .then(^(WMFRelatedSearchResults* readMoreResults) {
        @strongify(self);
        if ([readMoreResults.results count] > 0) {
            [self.webViewController setFooterViewControllers:@[self.readMoreListViewController]];
            [self appendReadMoreTableOfContentsItem];
        }
    }).catch(^(NSError* error){
        DDLogError(@"Read More Fetch Error: %@", [error localizedDescription]);
    });
}

#pragma mark - Scroll Position and Fragments

- (void)scrollWebViewToRequestedPosition {
    if (self.articleTitle.fragment) {
        [self.webViewController scrollToFragment:self.articleTitle.fragment];
    } else if ([self.historyEntry discoveryMethodRequiresScrollPositionRestore] && self.historyEntry.scrollPosition > 0) {
        [self.webViewController scrollToVerticalOffset:self.historyEntry.scrollPosition];
    }
    [self markFragmentAsProcessed];
}

- (void)markFragmentAsProcessed {
    //Create a title without the fragment so it wont be followed anymore
    self.articleTitle = [[MWKTitle alloc] initWithSite:self.articleTitle.site normalizedTitle:self.articleTitle.text fragment:nil];
}

#pragma mark - Share

- (void)shareArticleWithTextSnippet:(nullable NSString*)text fromButton:(nullable UIButton*)button {
    if (text.length == 0) {
        text = [self.article shareSnippet];
    }
    [self.shareFunnel logShareButtonTappedResultingInSelection:text];
    [self.shareOptionsController presentShareOptionsWithSnippet:text inViewController:self fromView:button];
}

#pragma mark - WebView Transition

- (void)showWebViewAtFragment:(NSString*)fragment animated:(BOOL)animated {
    [self.webViewController scrollToFragment:fragment];
}

#pragma mark - WMFWebViewControllerDelegate

- (void)         webViewController:(WebViewController*)controller
    didTapImageWithSourceURLString:(nonnull NSString*)imageSourceURLString {
    MWKImage* selectedImage = [[MWKImage alloc] initWithArticle:self.article sourceURLString:imageSourceURLString];
    /*
       NOTE(bgerstle): not setting gallery delegate intentionally to prevent header gallery changes as a result of
       fullscreen gallery interactions that originate from the webview
     */
    WMFModalImageGalleryViewController* fullscreenGallery =
        [[WMFModalImageGalleryViewController alloc] initWithImagesInArticle:self.article
                                                               currentImage:selectedImage];
    [self presentViewController:fullscreenGallery animated:YES completion:nil];
}

- (void)webViewController:(WebViewController*)controller didLoadArticle:(MWKArticle*)article {
    if (self.webViewIsLoadingFetchedArticle) {
        [self updateProgress:1.0 animated:YES];
        [self hideProgressViewAnimated:YES];
        self.webViewIsLoadingFetchedArticle = NO;
    }
    [self scrollWebViewToRequestedPosition];
}

- (void)webViewController:(WebViewController*)controller didTapEditForSection:(MWKSection*)section {
    [self showEditorForSection:section];
}

- (void)webViewController:(WebViewController*)controller didTapOnLinkForTitle:(MWKTitle*)title {
    [self wmf_pushArticleViewControllerWithTitle:title discoveryMethod:MWKHistoryDiscoveryMethodLink dataStore:self.dataStore];
}

- (void)webViewController:(WebViewController*)controller didSelectText:(NSString*)text {
    [self.shareFunnel logHighlight];
}

- (void)webViewController:(WebViewController*)controller didTapShareWithSelectedText:(NSString*)text {
    [self shareArticleWithTextSnippet:text fromButton:nil];
}

- (nullable NSString*)webViewController:(WebViewController*)controller titleForFooterViewController:(UIViewController*)footerViewController {
    if (footerViewController == self.readMoreListViewController) {
        return [MWSiteLocalizedString(self.articleTitle.site, @"article-read-more-title", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    }
    return nil;
}

#pragma mark - Analytics

- (NSString*)analyticsName {
    return [self.article analyticsName];
}

#pragma mark - WMFArticleHeadermageGalleryViewControllerDelegate

- (void)headerImageGallery:(WMFArticleHeaderImageGalleryViewController* __nonnull)gallery
     didSelectImageAtIndex:(NSUInteger)index {
    WMFModalImageGalleryViewController* fullscreenGallery;

    if (self.article.isCached) {
        fullscreenGallery = [[WMFModalImageGalleryViewController alloc] initWithImagesInArticle:self.article
                                                                                   currentImage:nil];
        fullscreenGallery.currentPage = gallery.currentPage;
    } else {
        /*
           In case the user taps on the lead image before the article is loaded, present the gallery w/ the lead image
           as a placeholder, then populate it in-place once the article is fetched.
         */
        NSAssert(index == 0, @"Unexpected selected index for uncached article. Only expecting lead image tap.");
        if (!self.articleFetcherPromise) {
            // Fetch the article if it hasn't been fetched already
            DDLogInfo(@"User tapped lead image before article fetch started, fetching before showing gallery.");
            [self fetchArticle];
        }
        fullscreenGallery =
            [[WMFModalImageGalleryViewController alloc] initWithImagesInFutureArticle:self.articleFetcherPromise
                                                                          placeholder:self.article];
    }

    // set delegate to ensure the header gallery is updated when the fullscreen gallery is dismissed
    fullscreenGallery.delegate = self;

    [self presentViewController:fullscreenGallery animated:YES completion:nil];
}

#pragma mark - WMFModalArticleImageGalleryViewControllerDelegate

- (void)willDismissGalleryController:(WMFModalImageGalleryViewController* __nonnull)gallery {
    self.headerGallery.currentPage = gallery.currentPage;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - WMFSearchPresentationDelegate

- (MWKDataStore*)searchDataStore {
    return self.dataStore;
}

- (void)didSelectTitle:(MWKTitle*)title sender:(id)sender discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    [self dismissViewControllerAnimated:YES completion:^{
        [self wmf_pushArticleViewControllerWithTitle:title
                                     discoveryMethod:discoveryMethod
                                           dataStore:self.dataStore];
    }];
}

- (void)didCommitToPreviewedArticleViewController:(WMFArticleContainerViewController*)articleViewController
                                           sender:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self wmf_pushArticleViewController:articleViewController];
    }];
}

#pragma mark - Edit Section

- (void)showEditorForSection:(MWKSection*)section {
    if (self.article.editable) {
        SectionEditorViewController* sectionEditVC = [SectionEditorViewController wmf_initialViewControllerFromClassStoryboard];
        sectionEditVC.section  = section;
        sectionEditVC.delegate = self;
        [self.navigationController pushViewController:sectionEditVC animated:YES];
    } else {
        ProtectedEditAttemptFunnel* funnel = [[ProtectedEditAttemptFunnel alloc] init];
        [funnel logProtectionStatus:[[self.article.protection allowedGroupsForAction:@"edit"] componentsJoinedByString:@","]];
        [self showProtectedDialog];
    }
}

- (void)showProtectedDialog {
    UIAlertView* alert = [[UIAlertView alloc] init];
    alert.title   = MWLocalizedString(@"page_protected_can_not_edit_title", nil);
    alert.message = MWLocalizedString(@"page_protected_can_not_edit", nil);
    [alert addButtonWithTitle:@"OK"];
    alert.cancelButtonIndex = 0;
    [alert show];
}

#pragma mark - SectionEditorViewControllerDelegate

- (void)sectionEditorFinishedEditing:(SectionEditorViewController*)sectionEditorViewController {
    [self.navigationController popToViewController:self animated:YES];
    [self fetchArticle];
}

#pragma mark - UIViewControllerPreviewingDelegate

- (void)registerForPreviewingIfAvailable {
    [self wmf_ifForceTouchAvailable:^{
        [self unregisterForPreviewing];
        UIView* previewView = [self.webViewController.webView wmf_browserView];
        self.linkPreviewingContext =
            [self registerForPreviewingWithDelegate:self sourceView:previewView];
        for (UIGestureRecognizer* r in previewView.gestureRecognizers) {
            [r requireGestureRecognizerToFail:self.linkPreviewingContext.previewingGestureRecognizerForFailureRelationship];
        }
    } unavailable:^{
        [self unregisterForPreviewing];
    }];
}

- (void)unregisterForPreviewing {
    if (self.linkPreviewingContext) {
        [self unregisterForPreviewingWithContext:self.linkPreviewingContext];
        self.linkPreviewingContext = nil;
    }
}

- (nullable UIViewController*)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
                      viewControllerForLocation:(CGPoint)location {
    JSValue* peekElement = [self.webViewController htmlElementAtLocation:location];
    if (!peekElement) {
        return nil;
    }

    NSURL* peekURL = [self.webViewController urlForHTMLElement:peekElement];
    if (!peekURL) {
        return nil;
    }

    UIViewController* peekVC = [self viewControllerForPreviewURL:peekURL];
    if (peekVC) {
        self.webViewController.isPeeking = YES;
        previewingContext.sourceRect     = [self.webViewController rectForHTMLElement:peekElement];
        return peekVC;
    }

    return nil;
}

- (UIViewController*)viewControllerForPreviewURL:(NSURL*)url {
    if (![url wmf_isInternalLink]) {
        return [[SFSafariViewController alloc] initWithURL:url];
    } else {
        if (![url wmf_isIntraPageFragment]) {
            return [[WMFArticleContainerViewController alloc] initWithArticleTitle:[[MWKTitle alloc] initWithURL:url]
                                                                         dataStore:self.dataStore
                                                                   discoveryMethod:self.discoveryMethod];
        }
    }
    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
     commitViewController:(UIViewController*)viewControllerToCommit {
    if ([viewControllerToCommit isKindOfClass:[WMFArticleContainerViewController class]]) {
        [self wmf_pushArticleViewController:(WMFArticleContainerViewController*)viewControllerToCommit];
    } else {
        [self presentViewController:viewControllerToCommit animated:YES completion:nil];
    }
}

@end

NS_ASSUME_NONNULL_END
