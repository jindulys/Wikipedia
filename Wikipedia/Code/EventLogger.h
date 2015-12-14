//  Created by Monte Hurd on 4/11/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

extern NSString* const WMFLoggingEndpoint;

@interface EventLogger : NSObject

/**
 * Most code should not call this directly -- use an EventLoggingFunnel subclass.
 */
- (instancetype)initAndLogEvent:(NSDictionary*)event
                      forSchema:(NSString*)schema
                       revision:(int)revision
                           wiki:(NSString*)wiki;

@end
