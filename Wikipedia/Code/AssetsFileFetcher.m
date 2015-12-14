//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "AssetsFileFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "QueuesSingleton.h"
#import "WMFAssetsFile.h"

NSTimeInterval const kWMFMaxAgeDefault = 60 * 60 * 24;

@implementation AssetsFileFetcher

- (instancetype)initAndFetchAssetsFileOfType:(WMFAssetsFileType)file
                                 withManager:(AFHTTPRequestOperationManager*)manager
                                      maxAge:(NSTimeInterval)maxAge {
    self = [super init];
    if (self) {
        self.fetchFinishedDelegate = nil;
        [self fetchAssetsFile:file
                       maxAge:maxAge
                  withManager:manager];
    }
    return self;
}

- (void)fetchAssetsFile:(WMFAssetsFileType)file
                 maxAge:(NSTimeInterval)maxAge
            withManager:(AFHTTPRequestOperationManager*)manager;
{
    WMFAssetsFile* assetsFile = [[WMFAssetsFile alloc] initWithFileType:file];

    // Cancel the operation if the existing file hasn't aged enough.
    BOOL shouldRefresh = [assetsFile isOlderThan:maxAge];

    if (!shouldRefresh) {
        return;
    }

    NSURL* url = assetsFile.url;

    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager GET:url.absoluteString parameters:nil success:^(AFHTTPRequestOperation* operation, id responseObject) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        if (operation.response.statusCode != 200) {
            return;
        }

        //NSString *className = NSStringFromClass ([responseObject class]);
        //NSLog(@"className = %@", className);
        //NSLog(@"mimeType = %@", operation.response.MIMEType);

        if (![self isDataResponseValid:responseObject]) {
            return;
        }

        NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];

        if ([responseString hasPrefix:@"/*\nInternal error\n*"]) {
            return;
        }

        NSError* error = nil;

        [responseString writeToFile:assetsFile.path
                         atomically:YES
                           encoding:NSUTF8StringEncoding
                              error:&error];
    } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        NSLog(@"Error: %@", error);
        //NSLog(@"Error URL: %@", operation.request.URL);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];
    }];
}

/*
   -(void)dealloc
   {
    NSLog(@"DEALLOC'ING ASSETS FILE FETCHER!");
   }
 */

@end
