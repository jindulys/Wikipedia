
#import "MWKTitleLanguageController.h"
#import "MWKTitle.h"
#import "MWKLanguageLink.h"
#import "MWKLanguageLinkController.h"
#import "MWKLanguageLinkFetcher.h"
#import "QueuesSingleton.h"

NS_ASSUME_NONNULL_BEGIN

@interface MWKTitleLanguageController ()

@property (copy, nonatomic, readwrite) MWKTitle* title;
@property (strong, nonatomic, readwrite) MWKLanguageLinkController* languageController;
@property (strong, nonatomic) MWKLanguageLinkFetcher* fetcher;
@property (copy, nonatomic) NSArray* availableLanguages;
@property (readwrite, copy, nonatomic) NSArray* allLanguages;
@property (readwrite, copy, nonatomic) NSArray* preferredLanguages;
@property (readwrite, copy, nonatomic) NSArray* otherLanguages;

@end

@implementation MWKTitleLanguageController

- (instancetype)initWithTitle:(MWKTitle*)title languageController:(MWKLanguageLinkController*)controller {
    self = [super init];
    if (self) {
        self.title              = title;
        self.languageController = controller;
    }
    return self;
}

- (MWKLanguageLinkFetcher*)fetcher {
    if (!_fetcher) {
        _fetcher = [[MWKLanguageLinkFetcher alloc] initWithManager:[[QueuesSingleton sharedInstance] languageLinksFetcher]
                                                          delegate:nil];
    }
    return _fetcher;
}

- (void)fetchLanguagesWithSuccess:(dispatch_block_t)success
                          failure:(void (^ __nullable)(NSError* __nonnull))failure {
    [[QueuesSingleton sharedInstance].languageLinksFetcher.operationQueue cancelAllOperations];
    [self.fetcher fetchLanguageLinksForTitle:self.title
                                     success:^(NSArray* languageLinks) {
        self.availableLanguages = languageLinks;
        if (success) {
            success();
        }
    }
                                     failure:failure];
}

- (void)setAvailableLanguages:(NSArray*)availableLanguages {
    _availableLanguages = availableLanguages;
    [self updateLanguageArrays];
}

- (void)updateLanguageArrays {
    self.otherLanguages = [[self.languageController.otherLanguages bk_select:^BOOL (MWKLanguageLink* language) {
        return [self languageIsAvailable:language];
    }] bk_map:^id (MWKLanguageLink* language) {
        return [self titleLanguageForLanguage:language];
    }];

    self.preferredLanguages = [[self.languageController.preferredLanguages bk_select:^BOOL (MWKLanguageLink* language) {
        return [self languageIsAvailable:language];
    }] bk_map:^id (MWKLanguageLink* language) {
        return [self titleLanguageForLanguage:language];
    }];

    self.allLanguages = [[self.languageController.allLanguages bk_select:^BOOL (MWKLanguageLink* language) {
        return [self languageIsAvailable:language];
    }] bk_map:^id (MWKLanguageLink* language) {
        return [self titleLanguageForLanguage:language];
    }];
}

- (nullable MWKLanguageLink*)titleLanguageForLanguage:(MWKLanguageLink*)language {
    return [self.availableLanguages bk_match:^BOOL (MWKLanguageLink* availableLanguage) {
        return [language.languageCode isEqualToString:availableLanguage.languageCode];
    }];
}

- (BOOL)languageIsAvailable:(MWKLanguageLink*)language {
    return [self titleLanguageForLanguage:language] != nil;
}

@end

NS_ASSUME_NONNULL_END
