

#import "MWKRecentSearchList.h"
#import "MWKList+Subclass.h"
#import "MediaWikiKit.h"

@interface MWKRecentSearchList ()

@property (readwrite, weak, nonatomic) MWKDataStore* dataStore;

@end

@implementation MWKRecentSearchList

#pragma mark - Setup

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    NSArray* entries = [[dataStore recentSearchListData] bk_map:^id (id obj) {
        @try {
            return [[MWKRecentSearchEntry alloc] initWithDict:obj];
        } @catch (NSException* e) {
            NSLog(@"Encountered exception while reading entry %@: %@", e, obj);
            return nil;
        }
    }];

    entries = [entries bk_reject:^BOOL (id obj) {
        if ([obj isEqual:[NSNull null]]) {
            return YES;
        }
        return NO;
    }];

    self = [super initWithEntries:entries];
    if (self) {
        self.dataStore = dataStore;
    }
    return self;
}

#pragma mark - Validation

- (BOOL)isEntryValid:(MWKRecentSearchEntry*)entry {
    return entry.searchTerm.length > 0 && entry.site;
}

#pragma mark - Data Update

- (void)importEntries:(NSArray*)entries {
    [super importEntries:[entries bk_select:^BOOL (MWKRecentSearchEntry* entry) {
        return [self isEntryValid:entry];
    }]];
}

- (void)addEntry:(MWKRecentSearchEntry*)entry {
    if (![self isEntryValid:entry]) {
        return;
    }
    [self removeEntryWithListIndex:entry.searchTerm];
    [self insertEntry:entry atIndex:0];
}

#pragma mark - Save

- (void)performSaveWithCompletion:(dispatch_block_t)completion error:(WMFErrorHandler)errorHandler {
    NSError* error;
    if ([self.dataStore saveRecentSearchList:self error:&error]) {
        if (completion) {
            completion();
        }
    } else {
        if (errorHandler) {
            errorHandler(error);
        }
    }
}

- (NSArray*)dataExport {
    return [self.entries bk_map:^id (MWKRecentSearchEntry* obj) {
        return [obj dataExport];
    }];
}

@end
