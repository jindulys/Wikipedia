
#import <Foundation/Foundation.h>

@class MWKSite;

NS_ASSUME_NONNULL_BEGIN

@interface WMFRandomArticleFetcher : NSObject

- (AnyPromise*)fetchRandomArticleWithSite:(MWKSite*)site;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END