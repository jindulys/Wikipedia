//
//  WMFGradientView.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFGradientView.h"

@implementation WMFGradientView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.gradientLayer setLocations:@[@0, @1]];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setStartColor:(UIColor*)startColor endColor:(UIColor*)endColor {
    _startColor = startColor;
    _endColor   = endColor;
    // HAX: need to provide clearColor defaults since IB might pass nil by setting
    // start/end separately
    [self.gradientLayer setColors:@[(id)startColor.CGColor ? : [UIColor clearColor],
                                    (id)endColor.CGColor ? : [UIColor clearColor]]];
}

- (void)setStartColor:(UIColor*)startColor {
    // need to support this for changes in IB
    [self setStartColor:startColor endColor:self.endColor];
}

- (void)setEndColor:(UIColor*)endColor {
    // need to support this for changes in IB
    [self setStartColor:self.startColor endColor:endColor];
}

- (void)setStartPoint:(CGPoint)startPoint {
    [self.gradientLayer setStartPoint:startPoint];
}

- (void)setEndPoint:(CGPoint)endPoint {
    [self.gradientLayer setEndPoint:endPoint];
}

#pragma mark - UIView

+ (Class)layerClass {
    return [CAGradientLayer class];
}

- (CAGradientLayer*)gradientLayer {
    return (CAGradientLayer*)self.layer;
}

@end
