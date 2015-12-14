//  Created by Brion on 11/1/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Mantle/MTLModel.h>
#import "MWKSite.h"

NS_ASSUME_NONNULL_BEGIN

@interface MWKTitle : MTLModel

#pragma mark - Permanent Properties

/**
 *  The site associated with the receiver.
 */
@property (readonly, strong, nonatomic) MWKSite* site;

/**
 *  The normalized page title string (decoded, no underscores or percent escapes).
 */
@property (readonly, copy, nonatomic) NSString* text;

#pragma mark - Initialization

/**
 * Initializes a new title belonging to @c site with an optional fragment.
 *
 * The preferred initializer is @c initWithString:site:, which parses components in the string.
 *
 * @param site      The site to which this title belongs.
 * @param text      The text which makes up the title.
 * @param fragment  An optional fragment, e.g. @"#section".
 *
 * @return A new title.
 */
- (instancetype)initWithSite:(MWKSite*)site
             normalizedTitle:(NSString*)text
                    fragment:(NSString* __nullable)fragment NS_DESIGNATED_INITIALIZER;

/**
 * Initialize a new title from the given string, parsing & escaping the title and fragment.
 * @param string    A string which represents a title. For example:
 * @param site      The site which this title lives under.
 * @see MWKTitleTests
 */
- (instancetype)initWithString:(NSString*)string site:(MWKSite*)site;

/// Initialize a new title with `relativeInternalLink`, which is parsed after removing the `/wiki/` prefix.
- (instancetype)initWithInternalLink:(NSString*)relativeInternalLink site:(MWKSite*)site;

/**
 * Initialize a new title with a URL, using its path and and host as the title's `text` and `site`.
 *
 * @param url URL pointing to a Wikipedia page (i.e. an internal link).
 *
 * @return A new title with properties parsed from the given URL, or `nil` if an error occurred.
 */
- (MWKTitle* __nullable)initWithURL:(NSURL*)url;

/// Convenience factory method wrapping `initWithString:site:`.
+ (MWKTitle*)titleWithString:(NSString*)str site:(MWKSite*)site;

#pragma mark - Comparison

- (BOOL)isEqualToTitle:(MWKTitle*)title;

- (BOOL)isEqualToTitleIncludingFragment:(MWKTitle*)title;

#pragma mark - Computed Properties

/// Text with spaces removed
@property (readonly, copy, nonatomic) NSString* dataBaseKey;

/// Text with spaces removed and special characters escaped for a URL
@property (readonly, copy, nonatomic) NSString* escapedURLText;

/// Fragment passed in designated initializer.
@property (readonly, copy, nonatomic, nullable) NSString* fragment;

/// Percent-escaped fragment, prefixed with @c #, or an empty string if absent.
@property (readonly, copy, nonatomic) NSString* escapedFragment;

/// Absolute URL to mobile view of this article
@property (readonly, copy, nonatomic) NSURL* mobileURL;

/// Absolute URL to desktop view of this article
@property (readonly, copy, nonatomic) NSURL* desktopURL;

@end

NS_ASSUME_NONNULL_END
