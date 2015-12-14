#import "WMFSearchFetcher_Testing.h"
#import "Wikipedia-Swift.h"

#import "WMFSearchResults_Internal.h"
#import "WMFSearchResults+ResponseSerializer.h"
#import "MWKSearchResult.h"

#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "WMFMantleJSONResponseSerializer.h"

#import "UIScreen+WMFImageWidth.h"

NS_ASSUME_NONNULL_BEGIN

NSUInteger const WMFMaxSearchResultLimit = 24;

#pragma mark - Internal Class Declarations

@interface WMFSearchRequestParameters : NSObject
@property (nonatomic, strong) NSString* searchTerm;
@property (nonatomic, assign) NSUInteger numberOfResults;
@property (nonatomic, assign) BOOL fullTextSearch;

@end

@interface WMFSearchRequestSerializer : AFHTTPRequestSerializer
@end


#pragma mark - Fetcher Implementation

@implementation WMFSearchFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
        manager.requestSerializer  = [WMFSearchRequestSerializer serializer];
        manager.responseSerializer = [WMFSearchResults responseSerializer];
        self.operationManager      = manager;
    }
    return self;
}

- (AnyPromise*)fetchArticlesForSearchTerm:(NSString*)searchTerm
                                     site:(MWKSite*)site
                              resultLimit:(NSUInteger)resultLimit {
    return [self fetchArticlesForSearchTerm:searchTerm site:site resultLimit:resultLimit fullTextSearch:NO appendToPreviousResults:nil];
}

- (AnyPromise*)fetchArticlesForSearchTerm:(NSString*)searchTerm
                                     site:(MWKSite*)site
                              resultLimit:(NSUInteger)resultLimit
                           fullTextSearch:(BOOL)fullTextSearch
                  appendToPreviousResults:(nullable WMFSearchResults*)results {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self fetchArticlesForSearchTerm:searchTerm site:site resultLimit:resultLimit fullTextSearch:fullTextSearch appendToPreviousResults:results useDesktopURL:NO resolver:resolve];
    }];
}

- (void)fetchArticlesForSearchTerm:(NSString*)searchTerm
                              site:(MWKSite*)site
                       resultLimit:(NSUInteger)resultLimit
                    fullTextSearch:(BOOL)fullTextSearch
           appendToPreviousResults:(nullable WMFSearchResults*)previousResults
                     useDesktopURL:(BOOL)useDeskTopURL
                          resolver:(PMKResolver)resolve {
    NSURL* url = [site apiEndpoint:useDeskTopURL];

    WMFSearchRequestParameters* params = [WMFSearchRequestParameters new];
    params.searchTerm      = searchTerm;
    params.numberOfResults = resultLimit;
    params.fullTextSearch  = fullTextSearch;

    [self.operationManager GET:url.absoluteString
                    parameters:params
                       success:^(AFHTTPRequestOperation* operation, id response) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        WMFSearchResults* searchResults = response;
        searchResults.searchTerm = searchTerm;

        if (!previousResults) {
            resolve(searchResults);
            return;
        }

        [previousResults mergeValuesForKeysFromModel:searchResults];

        resolve(previousResults);
    }
                       failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        if ([url isEqual:[site mobileApiEndpoint]] && [error wmf_shouldFallbackToDesktopURLError]) {
            [self fetchArticlesForSearchTerm:searchTerm site:site resultLimit:resultLimit fullTextSearch:fullTextSearch appendToPreviousResults:previousResults useDesktopURL:YES resolver:resolve];
        } else {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            resolve(error);
        }
    }];
}

@end

#pragma mark - Internal Class Implementations

@implementation WMFSearchRequestParameters

- (void)setNumberOfResults:(NSUInteger)numberOfResults {
    if (numberOfResults > WMFMaxSearchResultLimit) {
        DDLogError(@"Illegal attempt to request %lu articles, limiting to %lu.",
                   numberOfResults, WMFMaxSearchResultLimit);
        numberOfResults = WMFMaxSearchResultLimit;
    }
    _numberOfResults = numberOfResults;
}

@end

#pragma mark - Request Serializer

@implementation WMFSearchRequestSerializer

- (nullable NSURLRequest*)requestBySerializingRequest:(NSURLRequest*)request
                                       withParameters:(nullable id)parameters
                                                error:(NSError* __autoreleasing*)error {
    NSDictionary* serializedParams = [self serializedParams:(WMFSearchRequestParameters*)parameters];
    return [super requestBySerializingRequest:request withParameters:serializedParams error:error];
}

- (NSDictionary*)serializedParams:(WMFSearchRequestParameters*)params {
    NSNumber* numResults = @(params.numberOfResults);

    if (!params.fullTextSearch) {
        return @{
                   @"action": @"query",
                   @"generator": @"prefixsearch",
                   @"gpssearch": params.searchTerm,
                   @"gpsnamespace": @0,
                   @"gpslimit": numResults,
                   @"prop": @"pageterms|pageimages",
                   @"piprop": @"thumbnail",
                   @"wbptterms": @"description",
                   @"pithumbsize": [[UIScreen mainScreen] wmf_listThumbnailWidthForScale],
                   @"pilimit": numResults,
                   // -- Parameters causing prefix search to efficiently return suggestion.
                   @"list": @"search",
                   @"srsearch": params.searchTerm,
                   @"srnamespace": @0,
                   @"srwhat": @"text",
                   @"srinfo": @"suggestion",
                   @"srprop": @"",
                   @"sroffset": @0,
                   @"srlimit": @1,
                   @"redirects": @1,
                   // --
                   @"continue": @"",
                   @"format": @"json"
        };
    } else {
        return @{
                   @"action": @"query",
                   @"prop": @"pageterms|pageimages",
                   @"wbptterms": @"description",
                   @"generator": @"search",
                   @"gsrsearch": params.searchTerm,
                   @"gsrnamespace": @0,
                   @"gsrwhat": @"text",
                   @"gsrinfo": @"",
                   @"gsrprop": @"redirecttitle",
                   @"gsroffset": @0,
                   @"gsrlimit": numResults,
                   @"piprop": @"thumbnail",
                   @"pithumbsize": [[UIScreen mainScreen] wmf_listThumbnailWidthForScale],
                   @"pilimit": numResults,
                   @"continue": @"",
                   @"format": @"json",
                   @"redirects": @1,
        };
    }
}

@end


NS_ASSUME_NONNULL_END
