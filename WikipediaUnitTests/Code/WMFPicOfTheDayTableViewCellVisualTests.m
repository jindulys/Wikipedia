//
//  WMFPicOfTheDayTableViewCellVisualTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/25/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "FBSnapshotTestCase+WMFConvenience.h"
#import <Nocilla/LSNocilla.h>

#import "WMFPicOfTheDayTableViewCell_Testing.h"
#import "UIView+WMFDefaultNib.h"
#import "UIImageView+WMFImageFetchingInternal.h"
#import "WMFImageController+Testing.h"
#import "WMFHTTPHangingProtocol.h"
#import "WMFAsyncTestCase.h"
#import "UIImage+WMFStyle.h"

@interface WMFPicOfTheDayTableViewCellVisualTests : FBSnapshotTestCase

@property (nonatomic, strong) WMFPicOfTheDayTableViewCell* cell;

@end

@implementation WMFPicOfTheDayTableViewCellVisualTests

- (void)setUp {
    [super setUp];
    self.recordMode     = [[NSUserDefaults standardUserDefaults] wmf_visualTestBatchRecordMode];
    self.deviceAgnostic = YES;
    self.cell           = [WMFPicOfTheDayTableViewCell wmf_viewFromClassNib];
    [self.cell setDisplayTitle:@"Hey! I'm a display title!"];
    self.cell.potdImageView.wmf_imageController = [WMFImageController temporaryController];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInitialStateOnlyShowsPlaceholderWithoutCaption {
    [self wmf_verifyViewAtScreenWidth:self.cell];
}

- (void)testStillShowsPlaceholderWithoutCaptionWhileImageIsDownloading {
    [NSURLProtocol registerClass:[WMFHTTPHangingProtocol class]];
    [self.cell setImageURL:[NSURL URLWithString:@"http://dummyimage.com/foo"]];
    [self wmf_verifyViewAtScreenWidth:self.cell];
    [NSURLProtocol unregisterClass:[WMFHTTPHangingProtocol class]];
}

- (void)testShowsCaptionWhenImageIsFinallyDownloaded {
    [[LSNocilla sharedInstance] start];
    NSURL* testURL = [NSURL URLWithString:@"http://dummyimage.com/foo"];

    // using a plain-white image to ensure the gradient is visible
    UIImage* testImage = [UIImage wmf_imageFromColor:[UIColor whiteColor]];

    NSData* imageData = UIImagePNGRepresentation(testImage);

    stubRequest(@"GET", testURL.absoluteString)
    .andReturnRawResponse(imageData);

    [self.cell setImageURL:testURL];

    [self expectationForPredicate:[NSPredicate predicateWithBlock:^BOOL (UIImageView* _Nonnull potdImageView, NSDictionary < NSString*, id > * _Nullable bindings) {
        NSData* currentImageData = UIImagePNGRepresentation(potdImageView.image);
        return [currentImageData isEqualToData:imageData];
    }]
              evaluatedWithObject:self.cell.potdImageView
                          handler:nil];

    [self waitForExpectationsWithTimeout:5 handler:nil];

    [self wmf_verifyViewAtScreenWidth:self.cell];
    [[LSNocilla sharedInstance] stop];
}

@end
