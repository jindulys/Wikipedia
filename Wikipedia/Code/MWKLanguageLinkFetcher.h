//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

/*
   Note about langlinks:
   This returns info about *any* langlinks found on a page, which might not always directly lead to a
   translation of the current page. Specifically, main pages have lots of langlinks to other wikis' main pages. As such,
   they will all be returned in a lanklinks query[0], giving the client the (arguably false) impression that the EN wiki
   main page has been translated into other languages.

   0: https://en.wikipedia.org/w/api.php?action=query&titles=Main_Page&prop=langlinks&lllimit=500&format=json
 */

typedef NS_ENUM (NSInteger, LanguageLinksFetchErrorType) {
    LANGUAGE_LINKS_FETCH_ERROR_UNKNOWN = 0,
    LANGUAGE_LINKS_FETCH_ERROR_API     = 1
};

@class AFHTTPRequestOperationManager;

@interface MWKLanguageLinkFetcher : FetcherBase

/// Fetches the language links for the given page title.
- (instancetype)initAndFetchLanguageLinksForPageTitle:(MWKTitle*)title
                                          withManager:(AFHTTPRequestOperationManager*)manager
                                   thenNotifyDelegate:(id <FetchFinishedDelegate>)delegate;

- (instancetype)initWithManager:(AFHTTPRequestOperationManager*)manager
                       delegate:(id<FetchFinishedDelegate>)delegate;

- (void)fetchLanguageLinksForTitle:(MWKTitle*)title
                           success:(void (^)(NSArray* langLinks))success
                           failure:(void (^)(NSError* error))error;

@end
