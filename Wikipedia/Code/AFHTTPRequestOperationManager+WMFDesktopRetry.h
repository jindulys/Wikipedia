
#import <AFNetworking/AFHTTPRequestOperationManager.h>

@class MWKSite;

@interface AFHTTPRequestOperationManager (WMFDesktopRetry)

/**
 *  Executes a GET using a mobile url.
 *  If the request fails with the mobile URL for a known reason,
 *  the request will automatically be re-attempted with the desktop URL
 *
 *  @param mobileURLString  The mobile URL
 *  @param desktopURLString The desktop URL
 *  @param parameters       The parameters for the request (same as normal GET:)
 *  @param success          The retry block - called if a retry is executed. Use this to get the new operation.
 *  @param success          The success block (same as normal GET:)
 *  @param failure          The failure block (same as normal GET:)
 *
 *  @return The operation
 */
- (AFHTTPRequestOperation*)wmf_GETWithMobileURLString:(NSString*)mobileURLString
                                     desktopURLString:(NSString*)desktopURLString
                                           parameters:(id)parameters
                                                retry:(void (^)(AFHTTPRequestOperation* retryOperation, NSError* error))retry
                                              success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
                                              failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;


/**
 *  Send a @c GET request to the given site, falling back to desktop URL if the mobile URL fails.
 *
 *  @param site The site to send the request to, using its API endpoints. First mobile, then desktop.
 *
 *  @see wmf_GETWithMobileURLString:desktopURLString:parameters:retry:success:failure:
 *
 *  @return The operation which represents the state of the request.
 */
- (AFHTTPRequestOperation*)wmf_GETWithSite:(MWKSite*)site
                                parameters:(id)parameters
                                     retry:(void (^)(AFHTTPRequestOperation* retryOperation, NSError* error))retry
                                   success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
                                   failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;


/**
 *  Send a @c GET request to the given site, falling back to desktop URL if the mobile URL fails.
 *
 *  Convenience, promise-based alternative to block-based API.  Omits the retry parameter & operation return for the
 *  simple case which doesn't need cancellation.
 *
 *  @param site       The site to send the request to, using its API endpoints. First mobile, then desktop.
 *
 *  @param parameters The parameters which will be passed to the receiver's @c requestSerializer.
 *
 *  @return A promise which will be resolved with the successful response of the request, or rejected with any errors
 *          that occur.
 *
 *  @see wmf_GETWithMobileURLString:desktopURLString:parameters:retry:success:failure:
 */
- (AnyPromise*)wmf_GETWithSite:(MWKSite*)site parameters:(id)parameters;

@end
