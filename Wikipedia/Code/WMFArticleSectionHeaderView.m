//  Created by Monte Hurd on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFArticleSectionHeaderView.h"
#import <Masonry/Masonry.h>

@implementation WMFArticleSectionHeaderView

- (void)prepareForReuse {
    [super prepareForReuse];
    self.sectionHeaderLabel.text = @"";
}

@end
