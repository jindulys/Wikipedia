//
//  WMFNetworkUtilities.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

/// @name Constants

extern NSString* const WMFNetworkingErrorDomain;

typedef NS_ENUM (NSInteger, WMFNetworkingError) {
    WMFNetworkingError_APIError,
    WMFNetworkingError_InvalidParameters
};


/// @name Functions

/**
 * Take an array of strings and concatenate them with "|" as a delimiter.
 * @return A string of the concatenated elements, or an empty string if @c props is empty or @c nil.
 */
extern NSString* WMFJoinedPropertyParameters(NSArray* props);

extern NSError* WMFErrorForApiErrorObject(NSDictionary* apiError);

#import "FetcherBase.h"

@interface NSError (WMFFetchFinalStatus)

- (FetchFinalStatus)wmf_fetchStatus;

@end
