
#import "MWKSearchResult.h"
#import "NSURL+Extras.h"
#import "NSString+Extras.h"
#import "NSString+WMFHTMLParsing.h"

@interface MWKSearchResult ()

@property (nonatomic, assign, readwrite) NSInteger articleID;

@property (nonatomic, copy, readwrite) NSString* displayTitle;

@property (nonatomic, copy, readwrite) NSString* wikidataDescription;

@property (nonatomic, copy, readwrite) NSString* extract;

@property (nonatomic, copy, readwrite) NSURL* thumbnailURL;

@property (nonatomic, copy, readwrite) NSNumber* index;

@property (nonatomic, assign, readwrite) BOOL isDisambiguation;

@end

@implementation MWKSearchResult

- (instancetype)initWithArticleID:(NSInteger)articleID
                     displayTitle:(NSString*)displayTitle
              wikidataDescription:(NSString*)wikidataDescription
                          extract:(NSString*)extract
                     thumbnailURL:(NSURL*)thumbnailURL
                            index:(NSNumber*)index
                 isDisambiguation:(BOOL)isDisambiguation {
    self = [super init];
    if (self) {
        self.articleID           = articleID;
        self.displayTitle        = displayTitle;
        self.wikidataDescription = wikidataDescription;
        self.extract             = extract;
        self.thumbnailURL        = thumbnailURL;
        self.index               = index;
        self.isDisambiguation    = isDisambiguation;
    }
    return self;
}

+ (NSValueTransformer*)thumbnailURLJSONTransformer {
    return [MTLValueTransformer
            transformerUsingForwardBlock:^NSURL* (NSString* urlString,
                                                  BOOL* success,
                                                  NSError* __autoreleasing* error) {
                return [NSURL wmf_optionalURLWithString:urlString];
            }
            reverseBlock:^NSString* (NSURL* thumbnailURL,
                                     BOOL* success,
                                     NSError* __autoreleasing* error) {
                return [thumbnailURL absoluteString];
            }];
}

+ (NSValueTransformer*)wikidataDescriptionJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSArray* value, BOOL* success, NSError* __autoreleasing* error) {
        NSString* description = [value firstObject];
        return [description wmf_stringByCapitalizingFirstCharacter];
    }];
}

+ (MTLValueTransformer*)extractJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSString* extract, BOOL* success, NSError* __autoreleasing* error) {
        return [extract wmf_summaryFromText];
    }];
}

+ (NSValueTransformer*)isDisambiguationJSONTransformer {
    return [MTLValueTransformer
            transformerUsingForwardBlock:^(NSDictionary* value, BOOL* success, NSError** error) {
                NSString* disambiguation = value[@"pageprops.disambiguation"];
                if (disambiguation) {
                    return @YES;
                }
                // HAX: occasionally the search api doesn't report back "disambiguation" page term ( T121288 ),
                // so double-check wiki data description for "disambiguation page" string.
                NSArray* description = value[@"terms.description"];
                if (description.count && [description.firstObject containsString:@"disambiguation page"]) {
                    return @YES;
                }
                return @NO;
            }];
}

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
    return @{
             WMF_SAFE_KEYPATH(MWKSearchResult.new, displayTitle): @"title",
             WMF_SAFE_KEYPATH(MWKSearchResult.new, articleID): @"pageid",
             WMF_SAFE_KEYPATH(MWKSearchResult.new, thumbnailURL): @"thumbnail.source",
             WMF_SAFE_KEYPATH(MWKSearchResult.new, wikidataDescription): @"terms.description",
             WMF_SAFE_KEYPATH(MWKSearchResult.new, extract): @"extract",
             WMF_SAFE_KEYPATH(MWKSearchResult.new, index): @"index",
             WMF_SAFE_KEYPATH(MWKSearchResult.new, isDisambiguation): @[@"pageprops.disambiguation", @"terms.description"]
             };
}

@end
