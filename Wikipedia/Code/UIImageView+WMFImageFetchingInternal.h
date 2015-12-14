
#import "UIImageView+WMFImageFetching.h"

@class MWKImage;
@class WMFImageController;
@class WMFFaceDetectionCache;

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (WMFImageFetchingInternal)

/**
 *   The cache used to hold any detected faces
 *
 */
+ (WMFFaceDetectionCache*)faceDetectionCache;

/**
 *  The image URL associated with the receiver.
 *
 *  Used to ensure that images set on the receiver aren't associated with a URL for another metadata entity.
 */
@property (nonatomic, strong, nullable, setter = wmf_setImageURL:) NSURL* wmf_imageURL;

/**
 *  The metadata associated with the receiver.
 *
 *  This is preferred over @c wmf_imageURL since it allows for normalized face detection data to be read from and written
 *  to disk.
 *
 *  @see wmf_imageURL
 */
@property (nonatomic, strong, nullable, setter = wmf_setImageMetadata:) MWKImage* wmf_imageMetadata;

/**
 *  The image controller used to fetch image data.
 *
 *  Used to cancel the previous fetch executed by the receiver. Defaults to @c [WMFImageController sharedInstance].
 */
@property (nonatomic, weak, nullable, setter = wmf_setImageController:) WMFImageController* wmf_imageController;


/**
 *  The URL to fetch, depending on the current values of @c wmf_imageMetadata and @c wmf_imageURL.
 *
 *  @return A URL to the image to display in the receiver, or @c nil if none is set.
 */
@property (nonatomic, strong, nullable, readonly) NSURL* wmf_imageURLToFetch;

/**
 *  Fetch the receiver's @c wmf_imageURLToFetch
 *
 *  @param detectFaces Whether or not face detection & centering is desired.
 *
 *  @return A promise which resolves after the image has been successfully set and animated into view.
 */
- (AnyPromise*)wmf_fetchImageDetectFaces:(BOOL)detectFaces;

/**
 *  Cancels any ongoing fetch for the receiver's current image, using its internal @c WMFImageController.
 *
 *  @see wmf_imageURLToFetch
 */
- (void)wmf_cancelImageDownload;

@end

NS_ASSUME_NONNULL_END
