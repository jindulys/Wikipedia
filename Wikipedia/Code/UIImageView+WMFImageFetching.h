

#import <UIKit/UIKit.h>

@class MWKImage;

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (WMFImageFetching)

/**
 *  Sets the image to nil. Cancels any image requests.
 *
 *  It's recommended to call this before setting another image manually via `-[UIImage setImage:]`, but it's not
 *  necessary before another call to `-[UIImage wmf_setImageFromMetadata:options:withBlock:completion:onError:]`
 *  as these will implicitly cancel any pending image reqeusts.
 */
- (void)wmf_reset;

/**
 *  Set the receiver's @c image to the @c imageURL, optionally centering any faces found.
 *  Face detection data will be held in memory.
 *  THIS WILL NOT PERSIST THE RESULTS - IT WILL ONLY HOLD THE RESULTS IN MEMORY
 *
 *  @param imageURL url of the image you want to set.
 *  @param detectFaces Set to YES to detect faces.
 */
- (AnyPromise*)wmf_setImageWithURL:(NSURL*)imageURL detectFaces:(BOOL)detectFaces;

/**
 *  Set the receiver's @c image to the @c sourceURL of the given @c imageMetadata, optionally centering any faces found.
 *  Face detection data will be persisted in the imageMetadata
 *  THIS IS THE PREFERRED METHOD OF RESOLVING FACE DETECTION AS IT WILL PERSIST THE RESULTS
 *
 *  @param imageMetadata Metadata with the `sourceURL` of the image you want to set.
 *  @param detectFaces Set to YES to detect faces.
 */
- (AnyPromise*)wmf_setImageWithMetadata:(MWKImage*)imageMetadata detectFaces:(BOOL)detectFaces;

@end

NS_ASSUME_NONNULL_END
