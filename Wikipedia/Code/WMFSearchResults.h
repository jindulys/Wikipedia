
#import <Mantle/Mantle.h>

@class MWKSearchResult, MWKSearchRedirectMapping;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchResults : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString* searchTerm;
@property (nonatomic, strong, null_resettable, readonly) NSArray<MWKSearchResult*>* results;
@property (nonatomic, strong, null_resettable, readonly) NSArray<MWKSearchRedirectMapping*>* redirectMappings;

@property (nonatomic, copy, nullable, readonly) NSString* searchSuggestion;

- (instancetype)initWithSearchTerm:(NSString*)searchTerm
                           results:(nullable NSArray<MWKSearchResult*>*)results
                  searchSuggestion:(nullable NSString*)suggestion
                  redirectMappings:(NSArray<MWKSearchRedirectMapping*>*)redirectMappings;

@end

NS_ASSUME_NONNULL_END