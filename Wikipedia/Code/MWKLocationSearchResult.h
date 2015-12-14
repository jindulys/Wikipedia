
#import "MWKSearchResult.h"
@import CoreLocation;

/**
 *  Response object model for search results which have geocoordinates.
 *
 *  @warning This object only supports deserialization <b>from</b> JSON, not serialization <b>to</b> JSON.
 */
@interface MWKLocationSearchResult : MWKSearchResult<MTLJSONSerializing>

/**
 *  Location serialized from the first set of coordinates in the response.
 */
@property (nonatomic, strong, readonly) CLLocation* location;

/**
 *  Number of meters between the receiver and the coordinate parameters of the originating search.
 */
@property (nonatomic, assign, readonly) CLLocationDistance distanceFromQueryCoordinates;

@end
