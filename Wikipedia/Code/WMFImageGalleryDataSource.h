//
//  WMFImageGalleryDataSource.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/1/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Protocol which allows various data sources to be used by a base image gallery view controller class.
 *
 *  In other words, the data source can be used with any kind of gallery, as long as it has an image URL.
 */
@protocol WMFImageGalleryDataSource <NSObject>

- (NSURL*)imageURLAtIndexPath:(NSIndexPath*)indexPath;

@end
