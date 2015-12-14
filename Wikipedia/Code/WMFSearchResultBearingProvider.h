//
//  WMFSearchResultBearingProvider.h
//  Wikipedia
//
//  Created by Brian Gerstle on 9/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@import CoreLocation;

/**
 *  Object which provides a dynamic bearing to a specific location.
 *
 *  Provided by @c WMFNearbyViewModel, which updates instances of this class as the user's heading changes.
 */
@interface WMFSearchResultBearingProvider : NSObject

@property (nonatomic, assign) CLLocationDegrees bearingToLocation;

@end
