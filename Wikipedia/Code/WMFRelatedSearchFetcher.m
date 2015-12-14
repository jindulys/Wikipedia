
#import "WMFRelatedSearchFetcher.h"

//AFNetworking
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "AFHTTPRequestOperationManager+WMFDesktopRetry.h"
#import "WMFMantleJSONResponseSerializer.h"
#import <Mantle/Mantle.h>

//Promises
#import "Wikipedia-Swift.h"

//Models
#import "WMFRelatedSearchResults.h"
#import "MWKSearchResult.h"
#import "MWKTitle.h"

#import "NSDictionary+WMFCommonParams.h"

NS_ASSUME_NONNULL_BEGIN

NSUInteger const WMFMaxRelatedSearchResultLimit = 20;

#pragma mark - Internal Class Declarations

@interface WMFRelatedSearchRequestParameters : NSObject
@property (nonatomic, strong) MWKTitle* title;
@property (nonatomic, assign) NSUInteger numberOfResults;

@end

@interface WMFRelatedSearchRequestSerializer : AFHTTPRequestSerializer
@end

#pragma mark - Fetcher Implementation

@interface WMFRelatedSearchFetcher ()

@property (nonatomic, strong) AFHTTPRequestOperationManager* operationManager;

@end

@implementation WMFRelatedSearchFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
        manager.requestSerializer  = [WMFRelatedSearchRequestSerializer serializer];
        manager.responseSerializer =
            [WMFMantleJSONResponseSerializer serializerForValuesInDictionaryOfType:[MWKSearchResult class]
                                                                       fromKeypath:@"query.pages"];
        self.operationManager = manager;
    }
    return self;
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (AnyPromise*)fetchArticlesRelatedToTitle:(MWKTitle*)title
                               resultLimit:(NSUInteger)resultLimit {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        WMFRelatedSearchRequestParameters* params = [WMFRelatedSearchRequestParameters new];
        params.title = title;
        params.numberOfResults = resultLimit;

        [self.operationManager wmf_GETWithSite:title.site
                                    parameters:params
                                         retry:NULL
                                       success:^(AFHTTPRequestOperation* operation, id responseObject) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            resolve([[WMFRelatedSearchResults alloc] initWithTitle:title results:responseObject]);
        }
                                       failure:^(AFHTTPRequestOperation* operation, NSError* error) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            resolve(error);
        }];
    }];
}

@end

#pragma mark - Internal Class Implementations

@implementation WMFRelatedSearchRequestParameters

- (void)setNumberOfResults:(NSUInteger)numberOfResults {
    if (numberOfResults > WMFMaxRelatedSearchResultLimit) {
        DDLogError(@"Illegal attempt to request %lu articles, limiting to %lu.",
                   numberOfResults, WMFMaxRelatedSearchResultLimit);
        numberOfResults = WMFMaxRelatedSearchResultLimit;
    }
    _numberOfResults = numberOfResults;
}

@end

#pragma mark - Request Serializer

@implementation WMFRelatedSearchRequestSerializer

- (nullable NSURLRequest*)requestBySerializingRequest:(NSURLRequest*)request
                                       withParameters:(nullable id)parameters
                                                error:(NSError* __autoreleasing*)error {
    NSDictionary* serializedParams = [self serializedParams:(WMFRelatedSearchRequestParameters*)parameters];
    return [super requestBySerializingRequest:request withParameters:serializedParams error:error];
}

- (NSDictionary*)serializedParams:(WMFRelatedSearchRequestParameters*)params {
    NSNumber* numResults            = @(params.numberOfResults);
    NSMutableDictionary* baseParams = [NSMutableDictionary wmf_titlePreviewRequestParameters];
    [baseParams setValuesForKeysWithDictionary:@{
         @"generator": @"search",
         // search
         @"gsrsearch": [NSString stringWithFormat:@"morelike:%@", params.title.text],
         @"gsrnamespace": @0,
         @"gsrwhat": @"text",
         @"gsrinfo": @"",
         @"gsrprop": @"redirecttitle",
         @"gsroffset": @0,
         @"gsrlimit": numResults,
         // extracts
         @"exlimit": numResults,
         // pageimage
         @"pilimit": numResults,
     }];
    return baseParams;
}

@end

NS_ASSUME_NONNULL_END
