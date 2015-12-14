//
//  ShareCardViewController.m
//  Wikipedia
//
//  Created by Adam Baso on 1/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFShareCardViewController.h"
#import "NSString+Extras.h"
#import "WMFShareCardImageContainer.h"
#import "MWLanguageInfo.h"
#import "WikipediaAppUtils.h"
#import "MediaWikiKit.h"

@interface WMFShareCardViewController ()

@property (weak, nonatomic) IBOutlet WMFShareCardImageContainer* shareCardImageContainer;
@property (weak, nonatomic) IBOutlet UILabel* shareSelectedText;
@property (weak, nonatomic) IBOutlet UILabel* shareArticleTitle;
@property (weak, nonatomic) IBOutlet UILabel* shareArticleDescription;
@end


@implementation WMFShareCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_0) {
        // quick hack for font scaling on iOS 6
        self.shareArticleTitle.numberOfLines       = 1;
        self.shareArticleDescription.numberOfLines = 1;
        self.shareSelectedText.numberOfLines       = 5;
        self.shareSelectedText.font                = [UIFont systemFontOfSize:30.0f];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)fillCardWithMWKArticle:(MWKArticle*)article snippet:(NSString*)snippet image:(UIImage*)image {
    // The layout system will transpose the Wikipedia logo, CC-BY-SA,
    // title, and Wikidata description for congruence with the lead
    // image's title and description, which is determined by system
    // language, so we just adjust the text layout accordingly for the
    // title and Wikidata description. For the snippet, we want to mimic
    // the webview's layout alignment, which is based upon actual article
    // language directionality.
    NSTextAlignment snippetAlignment =
        [MWLanguageInfo articleLanguageIsRTL:article] ? NSTextAlignmentRight : NSTextAlignmentLeft;
    self.shareSelectedText.text          = snippet;
    self.shareSelectedText.textAlignment = snippetAlignment;

    NSTextAlignment subtextAlignment = NSTextAlignmentNatural;
    self.shareArticleTitle.text          = [article.displaytitle wmf_stringByRemovingHTML];
    self.shareArticleTitle.textAlignment = subtextAlignment;
    self.shareArticleDescription.text    =
        [[article.entityDescription wmf_stringByRemovingHTML] wmf_stringByCapitalizingFirstCharacter];
    self.shareArticleDescription.textAlignment = subtextAlignment;

    BOOL leadImageCached = [article.image.largestCachedVariant isDownloaded];
    if (leadImageCached) {
        // in case the image has transparency, make its container white
        self.shareCardImageContainer.image           = image;
        self.shareCardImageContainer.backgroundColor = [UIColor whiteColor];
        self.shareCardImageContainer.leadImage       = article.image.largestCachedVariant;
    }
}

@end
