//
//  WMFGradientView.h
//  Wikipedia
//
//  Created by Brian Gerstle on 3/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CAGradientLayer;

IB_DESIGNABLE
@interface WMFGradientView : UIView

@property (nonatomic, strong, readonly) CAGradientLayer* gradientLayer;

///
/// @name Configuring the Gradient
///

/**
 *  The starting color for the underlying @c gradientLayer.
 *
 *  This is only exposed for use in Interface Builder.  To set this programmatically, use <code>-setStartColor:endColor:</code>.
 */
@property (nonatomic, strong) IBInspectable UIColor* startColor;

/**
 *  The end color for the underlying @c gradientLayer.
 *
 *  This is only exposed for use in Interface Builder.  To set this programmatically, use <code>-setStartColor:endColor:</code>.
 */
@property (nonatomic, strong) IBInspectable UIColor* endColor;

/**
 *  Set the start and end color for the underlying gradient.
 *
 *  These must be set together due to the <code>-[CAGradientLayer setColors:]</code> API forcing them to be set all at once.
 *  This API only allows a start/end color to match the IBDesignable properties for the common use case.
 *
 *  @param startColor The color the gradient starts fading from.
 *  @param endColor   The color the gradient fades to.
 */
- (void)setStartColor:(UIColor*)startColor endColor:(UIColor*)endColor;

///
/// @name Configuring the gradient display range
///

/**
 *  Set the point at which the gradient starts fading from @c startColor to @c endColor.
 *
 *  Points should be normalized, and in the CoreGraphics coordinate space: between <code>[0,1]</code> where
 *  <code>[0,0]</code> is the top left corner of the view.
 *
 *  @see CAGradientLayer.startPoint
 */
@property (nonatomic, assign) IBInspectable CGPoint startPoint;

/**
 *  Set the point at which the gradient finishes fading to @c endColor.
 *
 *  Points should be normalized, and in the CoreGraphics coordinate space: between <code>[0,1]</code> where
 *  <code>[0,0]</code> is the top left corner of the view.
 *
 *  @see CAGradientLayer.endPoint
 */
@property (nonatomic, assign) IBInspectable CGPoint endPoint;

@end
