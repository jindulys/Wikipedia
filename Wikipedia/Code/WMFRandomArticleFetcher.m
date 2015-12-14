
#import "WMFRandomArticleFetcher.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "AFHTTPRequestOperationManager+WMFDesktopRetry.h"
#import "WMFApiJsonResponseSerializer.h"
#import "WMFMantleJSONResponseSerializer.h"
#import "WMFNumberOfExtractCharacters.h"

#import "MWKSite.h"
#import "MWKSearchResult.h"

//Promises
#import "Wikipedia-Swift.h"
#import "UIScreen+WMFImageWidth.h"

#import <BlocksKit/BlocksKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFRandomArticleFetcher ()

@property (nonatomic, strong) MWKSite* site;
@property (nonatomic, strong) AFHTTPRequestOperationManager* operationManager;

@end

@implementation WMFRandomArticleFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
        manager.responseSerializer = [WMFMantleJSONResponseSerializer serializerForValuesInDictionaryOfType:[MWKSearchResult class]
                                                                                                fromKeypath:@"query.pages"];
        self.operationManager = manager;
    }
    return self;
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (AnyPromise*)fetchRandomArticleWithSite:(MWKSite*)site {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        NSDictionary* params = [[self class] params];

        [self.operationManager wmf_GETWithSite:site
                                    parameters:params
                                         retry:NULL
                                       success:^(AFHTTPRequestOperation* operation, NSArray* responseObject) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];

            MWKSearchResult* article = [self getBestRandomResultFromResults:responseObject];

            resolve(article);
        } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            resolve(error);
        }];
    }];
}

- (MWKSearchResult*)getBestRandomResultFromResults:(NSArray*)results {
    //Sort so random results with good extracts and images come first and disambiguation pages come last.
    NSSortDescriptor* extractSorter  = [[NSSortDescriptor alloc] initWithKey:@"extract.length" ascending:NO];
    NSSortDescriptor* descripSorter  = [[NSSortDescriptor alloc] initWithKey:@"wikidataDescription" ascending:NO];
    NSSortDescriptor* thumbSorter    = [[NSSortDescriptor alloc] initWithKey:@"thumbnailURL" ascending:NO];
    NSSortDescriptor* disambigSorter = [[NSSortDescriptor alloc] initWithKey:@"isDisambiguation" ascending:YES];
    results = [results sortedArrayUsingDescriptors:@[disambigSorter, extractSorter, thumbSorter, descripSorter]];
    return [results firstObject];
}

+ (NSDictionary*)params {
    return @{
               @"action": @"query",
               @"prop": @"extracts|pageterms|pageimages|pageprops",
               //random
               @"generator": @"random",
               @"grnnamespace": @0,
               @"grnfilterredir": @"nonredirects",
               @"grnlimit": @"8",
               // extracts
               @"exintro": @YES,
               @"exlimit": @"1",
               @"explaintext": @"",
               @"exchars": @(WMFNumberOfExtractCharacters),
               // pageterms
               @"wbptterms": @"description",
               // pageimage
               @"piprop": @"thumbnail",
               @"pithumbsize": [[UIScreen mainScreen] wmf_leadImageWidthForScale],
               @"pilimit": @"1",
               @"format": @"json",
    };
}

@end


NS_ASSUME_NONNULL_END