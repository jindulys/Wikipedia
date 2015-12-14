//
//  NSURL+WMFLinkParsing.h
//  Wikipedia
//
//  Created by Brian Gerstle on 8/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WMFArticleNavigationDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (WMFLinkParsing)

- (BOOL)wmf_isInternalLink;

- (BOOL)wmf_isCitation;

- (NSString*)wmf_internalLinkPath;

- (void)wmf_informNavigationDelegate:(id<WMFArticleNavigationDelegate>)delegate
                          withSender:(id<WMFArticleNavigation> __nullable)articleNavigator;

@end

NS_ASSUME_NONNULL_END
