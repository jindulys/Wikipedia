//  Created by Monte Hurd on 7/25/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@class WebViewController, ReferenceVC;

@protocol ReferenceVCDelegate <NSObject>

- (void)referenceViewController:(ReferenceVC*)referenceViewController didShowReferenceWithLinkID:(NSString*)linkID;
- (void)referenceViewController:(ReferenceVC*)referenceViewController didFinishShowingReferenceWithLinkID:(NSString*)linkID;

- (void)referenceViewController:(ReferenceVC*)referenceViewController didSelectInternalReferenceWithFragment:(NSString*)fragment;
- (void)referenceViewController:(ReferenceVC*)referenceViewController didSelectReferenceWithTitle:(MWKTitle*)title;
- (void)referenceViewController:(ReferenceVC*)referenceViewController didSelectExternalReferenceWithURL:(NSURL*)url;

@end

@interface ReferenceVC : UIViewController <UIWebViewDelegate>

@property (assign, nonatomic) NSInteger index;

@property (strong, nonatomic) NSString* html;

@property (strong, nonatomic) NSString* linkId;
@property (strong, nonatomic) NSString* linkText;

@property (weak, nonatomic) id<ReferenceVCDelegate> delegate;

@end
