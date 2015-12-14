//
//  WMFSearchFunnel.m
//  Wikipedia
//
//  Created by Corey Floyd on 5/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFSearchFunnel.h"

static NSString* const kSchemaName            = @"MobileWikiAppSearch";
static int const kSchemaVersion               = 10641988;
static NSString* const kAppInstallIdKey       = @"appInstallID";
static NSString* const kSearchSessionTokenKey = @"searchSessionToken";

static NSString* const kActionKey          = @"action";
static NSString* const kSearchTypeKey      = @"typeOfSearch";
static NSString* const kSearchTimeKey      = @"timeToDisplayResults";
static NSString* const kSearchResultsCount = @"numberOfResults";

@interface WMFSearchFunnel ()

@property (nonatomic, strong) NSString* appInstallId;
@property (nonatomic, strong) NSString* searchSessionToken;

@end

@implementation WMFSearchFunnel

- (instancetype)init {
    self = [super initWithSchema:kSchemaName version:kSchemaVersion];
    if (self) {
        self.rate     = 100;
        _appInstallId = [self persistentUUID:kSchemaName];
    }
    return self;
}

- (NSString*)searchSessionToken {
    if (!_searchSessionToken) {
        _searchSessionToken = [[NSUUID UUID] UUIDString];
    }
    return _searchSessionToken;
}

- (NSDictionary*)preprocessData:(NSDictionary*)eventData {
    NSMutableDictionary* dict = [eventData mutableCopy];
    dict[kAppInstallIdKey]       = self.appInstallId;
    dict[kSearchSessionTokenKey] = self.searchSessionToken;
    return [dict copy];
}

- (void)logSearchStart {
    self.searchSessionToken = nil;
    [self log:@{kActionKey: @"start"}];
}

- (void)logSearchAutoSwitch {
    [self log:@{kActionKey: @"autoswitch"}];
}

- (void)logSearchDidYouMean {
    [self log:@{kActionKey: @"didyoumean"}];
}

- (void)logSearchResultTap {
    [self log:@{kActionKey: @"click"}];
}

- (void)logSearchCancel {
    [self log:@{kActionKey: @"cancel"}];
}

- (void)logSearchResultsWithTypeOfSearch:(WMFSearchType)type resultCount:(NSUInteger)count elapsedTime:(NSTimeInterval)searchTime {
    [self log:@{kActionKey: @"results",
                kSearchTypeKey: [[self class] stringForSearchType:type],
                kSearchResultsCount: @(count),
                kSearchTimeKey: @((NSInteger)(searchTime * 1000))}];
}

- (void)logShowSearchErrorWithTypeOfSearch:(WMFSearchType)type elapsedTime:(NSTimeInterval)searchTime {
    [self log:@{kActionKey: @"error",
                kSearchTypeKey: [[self class] stringForSearchType:type],
                kSearchTimeKey: @((NSInteger)(searchTime * 1000))}];
}

+ (NSString*)stringForSearchType:(WMFSearchType)type {
    if (type == WMFSearchTypePrefix) {
        return @"prefix";
    }

    return @"full";
}

@end
