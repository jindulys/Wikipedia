
#import <Foundation/Foundation.h>

@interface NSDateFormatter (WMFExtensions)

/**
 * Formatter which can be used to parse timestamps from the mediawiki API.
 *
 * @note It is safe to call this method from any thread.
 *
 * @return Singleton @c NSDateFormatter for transcoding WMF timestamps.
 */
+ (NSDateFormatter*)wmf_iso8601Formatter;

/**
 * Formatter which can be used to present a short time string for a given date.
 *
 * @warning Do not attempt to parse raw timestamps from the mediawiki API using this method. Use the unstyled
 *          @c +wmf_iso8601Formatter method instead.
 *
 * @note    This method is not thread safe, as it is intended to only be used by code which presents text to the user.
 *
 * @see +[NSDateFormatter wmf_iso8601Formatter]
 *
 * @return Singleton @c NSDateFormatter for displaying times to the user.
 */
+ (NSDateFormatter*)wmf_shortTimeFormatter;

/**
 * Create an short-style time formatter with the given locale.
 * @warning This method is exposed for testing only, use @c +wmf_shortTimeFormatter instead.
 */
+ (NSDateFormatter*)wmf_shortTimeFormatterWithLocale:(NSLocale*)locale;

/**
 * Create a long style date formatter. Sample: "April 24, 2015".
 */
+ (NSDateFormatter*)wmf_longDateFormatter;

+ (instancetype)wmf_mediumDateFormatterWithoutTime;

+ (instancetype)wmf_englishHyphenatedYearMonthDayFormatter;

@end
