//
//  WMFSearchResultDistanceProvider.h
//  Wikipedia
//
//  Created by Brian Gerstle on 9/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@import CoreLocation;

/**
 *  Object which provides a dynamic distance to a specific location.
 *
 *  Provided by @c WMFNearbyViewModel, which updates instances of this class as the user's location changes.
 */
@interface WMFSearchResultDistanceProvider : NSObject

@property (nonatomic, assign) CLLocationDistance distanceToUser;

@end
