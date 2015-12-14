//
//  Created by Brian Gerstle on 3/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFImageInfoController.h"

// Model
#import "MWKArticle.h"
#import "MWKDataStore.h"
#import "MWKImage.h"
#import "MWKImageList.h"
#import "MWKImageInfo+MWKImageComparison.h"

// Networking
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "AFHTTPRequestOperationManager+UniqueRequests.h"
#import "MWKImageInfoFetcher.h"
#import "MWKImageInfoResponseSerializer.h"

NS_ASSUME_NONNULL_BEGIN

extern NSDictionary* WMFIndexImageInfo(NSArray* __nullable imageInfo);

@interface WMFImageInfoController ()

@property (nonatomic, strong, readonly) NSMutableIndexSet* fetchedIndices;

/// Map of canonical filenames to image info objects.
@property (nonatomic, strong, readonly) NSDictionary* indexedImageInfo;

@property (nonatomic, strong) NSArray<MWKImage*>* uniqueArticleImages;

@property (nonatomic, strong, readonly) MWKImageInfoFetcher* imageInfoFetcher;

/**
 *  Title of the page that is associated with these image info objects.
 *
 *  Technically, image info don't belong to an article, but it was done this way for historical/legacy reasons. Mainly,
 *  that image metadata is also associated with a title.
 */
@property (nonatomic, strong, readwrite) MWKTitle* title;

/**
 *  Data store where image info will be read & written.
 */
@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;

/**
 *  Lazily calculated array of "File:" titles from the contents of @c uniqueArticleImages.
 *
 *  @warning The elements in this array can either be strings or @c NSNull in the event that a "File:" title couldn't
 *           be derived from the image URL.
 */
@property (nonatomic, strong, readonly) NSArray* imageFilePageTitles;

- (BOOL)hasFetchedAllItems;

- (NSRange)batchRangeForTargetIndex:(NSUInteger)index;

- (id<MWKImageInfoRequest> __nullable)fetchBatch:(NSRange)batch;

@end

NS_ASSUME_NONNULL_END
