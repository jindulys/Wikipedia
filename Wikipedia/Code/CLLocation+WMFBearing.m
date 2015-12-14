//
//  CLLocation+WMFBearing.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "CLLocation+WMFBearing.h"

@implementation CLLocation (WMFBearing)

- (CLLocationDegrees)wmf_bearingToLocation:(CLLocation*)destination {
    double const phiOrigin   = DEGREES_TO_RADIANS(self.coordinate.latitude),
                 phiDest     = DEGREES_TO_RADIANS(destination.coordinate.latitude),
                 deltaLambda = DEGREES_TO_RADIANS(destination.coordinate.longitude - self.coordinate.longitude),
                 y           = sin(deltaLambda) * cos(phiDest),
                 x           = cos(phiOrigin) * sin(phiDest) - sin(phiOrigin) * cos(phiDest) * cos(deltaLambda),
    // bearing in radians in range [-180, 180]
                 veBearingRadians = atan2(y, x);
    // convert to degrees and put in compass range [0, 360]
    return fmod(RADIANS_TO_DEGREES(veBearingRadians) + 360.0, 360.0);
}

- (CLLocationDegrees)wmf_bearingToLocation:(CLLocation*)location
                         forCurrentHeading:(CLHeading*)currentHeading {
    return [self wmf_bearingToLocation:location] - currentHeading.trueHeading;
}

@end
