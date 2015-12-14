//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

@class AFHTTPRequestOperationManager;

@interface PageHistoryFetcher : FetcherBase

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
- (instancetype)initAndFetchHistoryForTitle:(MWKTitle*)title
                                withManager:(AFHTTPRequestOperationManager*)manager
                         thenNotifyDelegate:(id <FetchFinishedDelegate>)delegate;

@end
