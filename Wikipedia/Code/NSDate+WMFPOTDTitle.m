//
//  NSDate+WMFPOTDTitle.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/2/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSDate+WMFPOTDTitle.h"
#import "NSDateFormatter+WMFExtensions.h"

NS_ASSUME_NONNULL_BEGIN

NSString* const WMFPOTDTitlePrefix = @"Template:Potd";

@implementation NSDate (WMFPOTDTitle)

- (NSString*)wmf_picOfTheDayPageTitle {
    NSString* potdTitleDateComponent = [[NSDateFormatter wmf_englishHyphenatedYearMonthDayFormatter] stringFromDate:self];
    NSParameterAssert(potdTitleDateComponent);
    return [WMFPOTDTitlePrefix stringByAppendingFormat:@"/%@", potdTitleDateComponent];
}

@end

NS_ASSUME_NONNULL_END
