
#import "WMFHomeSectionSchema.h"
#import "MWKSite.h"
#import "MWKDataStore.h"
#import "MWKSavedPageList.h"
#import "MWKHistoryList.h"
#import "WMFHomeSection.h"
#import "Wikipedia-Swift.h"
#import "NSDate+Utilities.h"
#import "WMFLocationManager.h"

@import Tweaks;
@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

static NSUInteger const WMFMaximumNumberOfHistoryAndSavedSections = 20;
static NSUInteger const WMFMaximumNumberOfFeaturedSections        = 10;

static NSTimeInterval const WMFHomeMinimumAutomaticReloadTime      = 600.0; //10 minutes
static NSTimeInterval const WMFTimeBeforeDisplayingLastReadArticle = 24 * 60 * 60; //24 hours

static CLLocationDistance const WMFMinimumDistanceBeforeUpdatingNearby = 500.0;

static NSString* const WMFHomeSectionsFileName      = @"WMFHomeSections";
static NSString* const WMFHomeSectionsFileExtension = @"plist";



@interface WMFHomeSectionSchema ()<WMFLocationManagerDelegate>

@property (nonatomic, strong, readwrite) MWKSite* site;
@property (nonatomic, strong, readwrite) MWKSavedPageList* savedPages;
@property (nonatomic, strong, readwrite) MWKHistoryList* historyPages;

@property (nonatomic, strong) WMFLocationManager* locationManager;

@property (nonatomic, strong, readwrite, nullable) NSDate* lastUpdatedAt;

@property (nonatomic, strong, readwrite) NSArray<WMFHomeSection*>* sections;

@end


@implementation WMFHomeSectionSchema

- (NSString*)description {
    // HAX: prevent this from logging all its properties in its description, as this causes recursion to
    // WMFLocationManager.description
    return [NSString stringWithFormat:@"<%@: %p>", [self class], self];
}

#pragma mark - Setup

+ (instancetype)schemaWithSite:(MWKSite*)site savedPages:(MWKSavedPageList*)savedPages history:(MWKHistoryList*)history {
    NSParameterAssert(site);
    NSParameterAssert(savedPages);
    NSParameterAssert(history);

    WMFHomeSectionSchema* schema = [self loadSchemaFromDisk];

    if (schema) {
        schema.site         = site;
        schema.savedPages   = savedPages;
        schema.historyPages = history;
    } else {
        schema = [[WMFHomeSectionSchema alloc] initWithSite:site savedPages:savedPages history:history];
    }

    return schema;
}

- (instancetype)initWithSite:(MWKSite*)site savedPages:(MWKSavedPageList*)savedPages history:(MWKHistoryList*)history {
    NSParameterAssert(site);
    NSParameterAssert(savedPages);
    NSParameterAssert(history);
    self = [super init];
    if (self) {
        self.site         = site;
        self.savedPages   = savedPages;
        self.historyPages = history;
        [self reset];
    }
    return self;
}

- (void)reset {
    NSMutableArray* startingSchema = [[WMFHomeSectionSchema startingSchema] mutableCopy];
    WMFHomeSection* saved          = [[self sectionsFromSavedEntriesExcludingExistingTitlesInSections:nil maxLength:1] firstObject];
    WMFHomeSection* recent         = [[self sectionsFromHistoryEntriesExcludingExistingTitlesInSections:saved ? @[saved] : nil maxLength:1] firstObject];
    if (recent) {
        [startingSchema addObject:recent];
    }
    if (saved) {
        [startingSchema addObject:saved];
    }

    self.lastUpdatedAt = nil;
    [self updateSections:startingSchema];
}

+ (NSArray*)startingSchema {
    return @[[WMFHomeSection mainPageSection],
             [WMFHomeSection nearbySectionWithLocation:nil],
             [WMFHomeSection randomSection]];
}

#pragma mark - Location

- (WMFLocationManager*)locationManager {
    if (_locationManager == nil) {
        _locationManager          = [[WMFLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

#pragma mark - Sections

- (void)updateSections:(NSArray<WMFHomeSection*>*)sections {
    self.sections = [sections sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult (WMFHomeSection* _Nonnull obj1, WMFHomeSection* _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    [self.delegate sectionSchemaDidUpdateSections:self];
    [WMFHomeSectionSchema saveSchemaToDisk:self];
}

#pragma mark - Update

- (void)update {
    [self update:NO];
}

- (void)update:(BOOL)force {
    //Check Tweak
    if (!FBTweakValue(@"Home", @"General", @"Always update on launch", NO)) {
        //Check force flag and minimum relaod time
        if (!force && self.lastUpdatedAt && [[NSDate date] timeIntervalSinceDate:self.lastUpdatedAt] < WMFHomeMinimumAutomaticReloadTime) {
            return;
        }
    }

    //Start updating the location
    [self.locationManager startMonitoringLocation];

    //Get updated static sections
    NSMutableArray<WMFHomeSection*>* sections = [[self staticSections] mutableCopy];

    //Add featured articles
    [sections addObjectsFromArray:[self featuredSections]];

    //Add Saved and History
    NSArray<WMFHomeSection*>* recent = [self historyAndSavedPageSections];
    if ([recent count] > 0) {
        [sections addObjectsFromArray:recent];
    }

    self.lastUpdatedAt = [NSDate date];
    [self updateSections:sections];
}

- (void)updateNearbySectionWithLocation:(CLLocation*)location {
    NSParameterAssert(location);

    WMFHomeSection* oldNearby = [self existingNearbySection];

    //Check Tweak
    if (!FBTweakValue(@"Home", @"Nearby", @"Always update on launch", NO)) {
        //Check didtance to old location
        if (oldNearby.location && [location distanceFromLocation:oldNearby.location] < WMFMinimumDistanceBeforeUpdatingNearby) {
            return;
        }
    }

    NSMutableArray<WMFHomeSection*>* sections = [self.sections mutableCopy];
    [sections bk_performReject:^BOOL (WMFHomeSection* obj) {
        return obj.type == WMFHomeSectionTypeNearby;
    }];

    [sections addObject:[self nearbySectionWithLocation:location]];

    [self updateSections:sections];
}

#pragma mmrk - Create Schema Items

- (NSArray*)staticSections {
    NSMutableArray<WMFHomeSection*>* sections = [NSMutableArray array];

    [sections wmf_safeAddObject:[self existingNearbySection]];
    [sections wmf_safeAddObject:[self randomSection]];
    [sections addObject:[self mainPageSection]];
    [sections addObject:[self picOfTheDaySection]];
    [sections wmf_safeAddObject:[self continueReadingSection]];

    return sections;
}

- (WMFHomeSection*)randomSection {
    WMFHomeSection* random = nil;

    MWKHistoryEntry* lastEntry = [self.historyPages.entries firstObject];

    if (![lastEntry.date isThisWeek]) {
        random = [self.sections bk_match:^BOOL (WMFHomeSection* obj) {
            if (obj.type == WMFHomeSectionTypeRandom) {
                return YES;
            }
            return NO;
        }];
    }

    //Always return a random section
    if (!random) {
        random = [WMFHomeSection randomSection];
    }

    return random;
}

- (WMFHomeSection*)nearbySectionWithLocation:(CLLocation*)location {
    return [WMFHomeSection nearbySectionWithLocation:location];
}

- (nullable WMFHomeSection*)existingNearbySection {
    WMFHomeSection* nearby = [self.sections bk_match:^BOOL (WMFHomeSection* obj) {
        if (obj.type == WMFHomeSectionTypeNearby) {
            return YES;
        }
        return NO;
    }];

    return nearby;
}

#pragma mark - Daily Sections

- (NSArray<WMFHomeSection*>*)featuredSections {
    NSArray* previous = [self.sections bk_select:^BOOL (WMFHomeSection* obj) {
        if (obj.type == WMFHomeSectionTypeFeaturedArticle) {
            return YES;
        }
        return NO;
    }];

    //Don't add new ones if we aren't in english
    if (![self.site.language isEqualToString:@"en"] && ![self.site.language isEqualToString:@"en-US"]) {
        return previous;
    }

    NSMutableArray* featured = [NSMutableArray array];
    [featured addObjectsFromArray:previous];

    WMFHomeSection* today = [featured bk_match:^BOOL (WMFHomeSection* obj) {
        if (obj.type == WMFHomeSectionTypeFeaturedArticle) {
            if ([obj.dateCreated isToday]) {
                return YES;
            }
        }
        return NO;
    }];

    if (!today) {
        [featured addObject:[WMFHomeSection featuredArticleSectionWithSite:self.site]];
    }

    NSUInteger max = FBTweakValue(@"Home", @"Sections", @"Max number of featured", WMFMaximumNumberOfFeaturedSections);

    //Sort by date
    [featured sortWithOptions:NSSortStable usingComparator:^NSComparisonResult (WMFHomeSection* _Nonnull obj1, WMFHomeSection* _Nonnull obj2) {
        return -[obj1.dateCreated compare:obj2.dateCreated];
    }];

    return [featured wmf_arrayByTrimmingToLength:max];
}

- (WMFHomeSection*)getOrCreateStaticTodaySectionOfType:(WMFHomeSectionType)type {
    WMFHomeSection* existingSection = [self.sections bk_match:^BOOL (WMFHomeSection* obj) {
        if (obj.type == type) {
            return YES;
        }
        return NO;
    }];

    //If it's a new day and we havent created a new main page section, create it now
    if ([existingSection.dateCreated isToday]) {
        return existingSection;
    }

    switch (type) {
        case WMFHomeSectionTypeMainPage:
            return [WMFHomeSection mainPageSection];
        case WMFHomeSectionTypePictureOfTheDay:
            return [WMFHomeSection pictureOfTheDaySection];

        default:
            NSAssert(NO, @"Cannot create static 'today' section of type %ld", type);
            return nil;
    }
}

- (WMFHomeSection*)mainPageSection {
    return [self getOrCreateStaticTodaySectionOfType:WMFHomeSectionTypeMainPage];
}

- (WMFHomeSection*)picOfTheDaySection {
    return [self getOrCreateStaticTodaySectionOfType:WMFHomeSectionTypePictureOfTheDay];
}

- (nullable WMFHomeSection*)continueReadingSection {
    NSDate* resignActiveDate             = [[NSUserDefaults standardUserDefaults] wmf_appResignActiveDate];
    BOOL const shouldShowContinueReading =
        FBTweakValue(@"Home", @"Continue Reading", @"Always Show", NO) ||
        fabs([resignActiveDate timeIntervalSinceNow]) >= WMFTimeBeforeDisplayingLastReadArticle;

    //Only return if
    if (shouldShowContinueReading) {
        MWKTitle* lastRead = [self.historyPages mostRecentEntry].title;
        if (lastRead) {
            return [WMFHomeSection continueReadingSectionWithTitle:lastRead];
        }
    }
    return nil;
}

- (NSArray<WMFHomeSection*>*)historyAndSavedPageSections {
    NSMutableArray<WMFHomeSection*>* sections = [NSMutableArray array];

    NSUInteger max = FBTweakValue(@"Home", @"Sections", @"Max number of history/saved", WMFMaximumNumberOfHistoryAndSavedSections);

    NSArray<WMFHomeSection*>* saved   = [self sectionsFromSavedEntriesExcludingExistingTitlesInSections:nil maxLength:max];
    NSArray<WMFHomeSection*>* history = [self sectionsFromHistoryEntriesExcludingExistingTitlesInSections:saved maxLength:max];

    [sections addObjectsFromArray:saved];
    [sections addObjectsFromArray:history];

    //Sort by date
    [sections sortWithOptions:NSSortStable | NSSortConcurrent usingComparator:^NSComparisonResult (WMFHomeSection* _Nonnull obj1, WMFHomeSection* _Nonnull obj2) {
        return -[obj1.dateCreated compare:obj2.dateCreated];
    }];

    return [sections wmf_arrayByTrimmingToLength:max];
}

- (NSArray<WMFHomeSection*>*)sectionsFromHistoryEntriesExcludingExistingTitlesInSections:(nullable NSArray<WMFHomeSection*>*)existingSections maxLength:(NSUInteger)maxLength {
    NSArray<MWKTitle*>* existingTitles = [existingSections valueForKeyPath:WMF_SAFE_KEYPATH([WMFHomeSection new], title)];

    NSArray<MWKHistoryEntry*>* entries = [self.historyPages.entries bk_select:^BOOL (MWKHistoryEntry* obj) {
        return obj.titleWasSignificantlyViewed;
    }];
    entries = [entries wmf_arrayByTrimmingToLength:maxLength + [existingSections count]];

    entries = [entries bk_reject:^BOOL (MWKHistoryEntry* obj) {
        return [existingTitles containsObject:obj.title];
    }];

    return [[entries bk_map:^id (MWKHistoryEntry* obj) {
        return [WMFHomeSection historySectionWithHistoryEntry:obj];
    }] wmf_arrayByTrimmingToLength:maxLength];
}

- (NSArray<WMFHomeSection*>*)sectionsFromSavedEntriesExcludingExistingTitlesInSections:(nullable NSArray<WMFHomeSection*>*)existingSections maxLength:(NSUInteger)maxLength {
    NSArray<MWKTitle*>* existingTitles = [existingSections valueForKeyPath:WMF_SAFE_KEYPATH([WMFHomeSection new], title)];

    NSArray<MWKSavedPageEntry*>* entries = [self.savedPages.entries wmf_arrayByTrimmingToLength:maxLength + [existingSections count]];

    entries = [entries bk_reject:^BOOL (MWKHistoryEntry* obj) {
        return [existingTitles containsObject:obj.title];
    }];

    return [[entries bk_map:^id (MWKSavedPageEntry* obj) {
        return [WMFHomeSection savedSectionWithSavedPageEntry:obj];
    }] wmf_arrayByTrimmingToLength:maxLength];
}

#pragma mark - WMFLocationManagerDelegate

- (void)nearbyController:(WMFLocationManager*)controller didUpdateLocation:(CLLocation*)location {
    [controller stopMonitoringLocation];
    [self updateNearbySectionWithLocation:location];
}

- (void)nearbyController:(WMFLocationManager*)controller didUpdateHeading:(CLHeading*)heading {
}

- (void)nearbyController:(WMFLocationManager*)controller didReceiveError:(NSError*)error {
}

#pragma mark - Persistance

+ (NSDictionary*)encodingBehaviorsByPropertyKey {
    NSMutableDictionary* behaviors = [[super encodingBehaviorsByPropertyKey] mutableCopy];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:@"site"];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:@"savedPages"];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:@"historyPages"];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:@"delegate"];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:@"locationManager"];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:@"locationRequestStarted"];
    return behaviors;
}

+ (NSURL*)schemaFileURL {
    return [NSURL fileURLWithPath:[[documentsDirectory() stringByAppendingPathComponent:WMFHomeSectionsFileName] stringByAppendingPathExtension:WMFHomeSectionsFileExtension]];
}

+ (void)saveSchemaToDisk:(WMFHomeSectionSchema*)schema {
    dispatchOnBackgroundQueue(^{
        if (![NSKeyedArchiver archiveRootObject:schema toFile:[[self schemaFileURL] path]]) {
            //TODO: not sure what to do with an error here
            DDLogError(@"Failed to save sections to disk!");
        }
    });
}

+ (WMFHomeSectionSchema*)loadSchemaFromDisk {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[[self schemaFileURL] path]];
}

@end

NS_ASSUME_NONNULL_END
