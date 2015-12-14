#import "MediaWikiKit.h"
#import "NSMutableDictionary+WMFMaybeSet.h"
#import "WikipediaAppUtils.h"
#import "WMFImageURLParsing.h"
#import "Wikipedia-Swift.h"

// !!!: don't change key constants w/o writing conversion code to pull values from the old keys
// Model Version 1.0.0
NSString* const mWKImageInfoModelVersionKey = @"modelVersion";
NSUInteger const MWKImageInfoModelVersion_1 = 1;

NSString* const MWKImageInfoCanonicalPageTitleKey = @"canonicalPageTitle";
NSString* const MWKImageInfoCanonicalFileURLKey   = @"canonicalFileURL";
NSString* const MWKImageInfoImageDescriptionKey   = @"imageDescription";
NSString* const MWKImageInfoFilePageURLKey        = @"filePageURL";
NSString* const MWKImageInfoImageThumbURLKey      = @"imageThumbURL";
NSString* const MWKImageInfoOwnerKey              = @"owner";
NSString* const MWKImageInfoLicenseKey            = @"license";
NSString* const MWKImageInfoImageSize             = @"imageSize";
NSString* const MWKImageInfoThumbSize             = @"thumbSize";


@interface MWKImageInfo ()

@property (nonatomic, readwrite, copy) NSString* canonicalPageTitle;
@property (nonatomic, readwrite, copy) NSURL* canonicalFileURL;
@property (nonatomic, readwrite, copy) NSString* imageDescription;
@property (nonatomic, readwrite, strong) MWKLicense* license;
@property (nonatomic, readwrite, copy) NSURL* filePageURL;
@property (nonatomic, readwrite, copy) NSURL* imageThumbURL;
@property (nonatomic, readwrite, assign) CGSize imageSize;
@property (nonatomic, readwrite, assign) CGSize thumbSize;
@property (nonatomic, readwrite, copy) NSString* owner;
@property (nonatomic, readwrite, strong) id imageAssociationValue;

@end


@implementation MWKImageInfo

- (instancetype)initWithCanonicalPageTitle:(NSString*)canonicalPageTitle
                          canonicalFileURL:(NSURL*)canonicalFileURL
                          imageDescription:(NSString*)imageDescription
                                   license:(MWKLicense*)license
                               filePageURL:(NSURL*)filePageURL
                             imageThumbURL:(NSURL*)imageThumbURL
                                     owner:(NSString*)owner
                                 imageSize:(CGSize)imageSize
                                 thumbSize:(CGSize)thumbSize {
    // !!!: not sure what's guaranteed by the API
    // NSParameterAssert(canonicalPageTitle.length);
    // NSParameterAssert(canonicalFileURL.absoluteString.length);
    self = [super init];
    if (self) {
        self.canonicalPageTitle = canonicalPageTitle;
        self.imageDescription   = imageDescription;
        self.owner              = owner;
        self.license            = license;
        self.canonicalFileURL   = canonicalFileURL;
        self.filePageURL        = filePageURL;
        self.imageThumbURL      = imageThumbURL;
        self.imageSize          = imageSize;
        self.thumbSize          = thumbSize;
    }
    return self;
}

+ (instancetype)imageInfoWithExportedData:(NSDictionary*)exportedData {
    if (!exportedData) {
        return nil;
    }
    // assume all model versions are 1.0.0
    return [[MWKImageInfo alloc]
            initWithCanonicalPageTitle:exportedData[MWKImageInfoCanonicalPageTitleKey]
                      canonicalFileURL:[NSURL URLWithString:exportedData[MWKImageInfoCanonicalFileURLKey]]
                      imageDescription:exportedData[MWKImageInfoImageDescriptionKey]
                               license:[MWKLicense licenseWithExportedData:exportedData[MWKImageInfoLicenseKey]]
                           filePageURL:[NSURL URLWithString:exportedData[MWKImageInfoFilePageURLKey]]
                         imageThumbURL:[NSURL URLWithString:exportedData[MWKImageInfoImageThumbURLKey]]
                                 owner:exportedData[MWKImageInfoOwnerKey]
                             imageSize:CGSizeFromString(exportedData[MWKImageInfoImageSize])
                             thumbSize:CGSizeFromString(exportedData[MWKImageInfoThumbSize])];
}

- (NSDictionary*)dataExport {
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:6];

    dict[mWKImageInfoModelVersionKey] = @(MWKImageInfoModelVersion_1);

    [dict wmf_maybeSetObject:self.canonicalPageTitle forKey:MWKImageInfoCanonicalPageTitleKey];
    [dict wmf_maybeSetObject:self.canonicalFileURL.absoluteString forKey:MWKImageInfoCanonicalFileURLKey];
    [dict wmf_maybeSetObject:self.imageDescription forKey:MWKImageInfoImageDescriptionKey];
    [dict wmf_maybeSetObject:self.filePageURL.absoluteString forKey:MWKImageInfoFilePageURLKey];
    [dict wmf_maybeSetObject:self.imageThumbURL.absoluteString forKey:MWKImageInfoImageThumbURLKey];
    [dict wmf_maybeSetObject:self.owner forKey:MWKImageInfoOwnerKey];

    [dict wmf_maybeSetObject:[self.license dataExport] forKey:MWKImageInfoLicenseKey];

    dict[MWKImageInfoImageSize] = NSStringFromCGSize(self.imageSize);
    dict[MWKImageInfoThumbSize] = NSStringFromCGSize(self.thumbSize);

    return [dict copy];
}

- (BOOL)isEqual:(id)obj {
    if (obj == self) {
        return YES;
    } else if ([obj isKindOfClass:[MWKImageInfo class]]) {
        return [self isEqualToImageInfo:obj];
    } else {
        return NO;
    }
}

- (BOOL)isEqualToImageInfo:(MWKImageInfo*)other {
    return WMF_EQUAL(self.canonicalPageTitle, isEqualToString:, other.canonicalPageTitle)
           && WMF_IS_EQUAL(self.canonicalFileURL, other.canonicalFileURL)
           && WMF_EQUAL(self.imageDescription, isEqualToString:, other.imageDescription)
           && WMF_EQUAL(self.license, isEqualToLicense:, other.license)
           && WMF_IS_EQUAL(self.filePageURL, other.filePageURL)
           && WMF_IS_EQUAL(self.imageThumbURL, other.imageThumbURL)
           && WMF_EQUAL(self.owner, isEqualToString:, other.owner)
           && CGSizeEqualToSize(self.imageSize, other.imageSize)
           && CGSizeEqualToSize(self.thumbSize, other.thumbSize);
}

- (NSUInteger)hash {
    return self.canonicalPageTitle.hash ^ flipBitsWithAdditionalRotation(self.canonicalFileURL.hash, 1);
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ %@ %@",
            [super description], self.canonicalPageTitle, self.canonicalFileURL];
}

#pragma mark - Calculated properties

- (id)imageAssociationValue {
    if (!_imageAssociationValue) {
        _imageAssociationValue = WMFParseImageNameFromSourceURL(self.canonicalFileURL);
    }
    return _imageAssociationValue;
}

- (NSString*)canonicalPageName {
    return [self.canonicalPageTitle wmf_safeSubstringFromIndex:@"File:".length];
}

@end
