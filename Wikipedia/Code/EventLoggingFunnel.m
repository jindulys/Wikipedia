//
//  EventLoggingFunnel.m
//  Wikipedia
//
//  Created by Brion on 5/28/14.
//  Copyright (c) 2014 Wikimedia Foundation. Some rights reserved.
//

#import "EventLoggingFunnel.h"
#import "EventLogger.h"
#import "QueuesSingleton.h"
#import "SessionSingleton.h"
#import "MediaWikiKit.h"

@implementation EventLoggingFunnel

- (id)initWithSchema:(NSString*)schema version:(int)revision {
    if (self) {
        self.schema   = schema;
        self.revision = revision;
        self.rate     = 1;
    }
    return self;
}

- (NSDictionary*)preprocessData:(NSDictionary*)eventData {
    return eventData;
}

- (void)log:(NSDictionary*)eventData {
    SessionSingleton* session = [SessionSingleton sharedInstance];
    NSString* wiki            = [session.currentArticleSite.language stringByAppendingString:@"wiki"];
    [self log:eventData wiki:wiki];
}

- (void)log:(NSDictionary*)eventData wiki:(NSString*)wiki {
    if ([SessionSingleton sharedInstance].shouldSendUsageReports) {
        BOOL chosen = NO;
        if (self.rate == 1) {
            chosen = YES;
        } else if (self.rate != 0) {
            chosen = (self.getEventLogSamplingID % self.rate) == 0;
        }
        if (chosen) {
            (void)[[EventLogger alloc] initAndLogEvent:[self preprocessData:eventData]
                                             forSchema:self.schema
                                              revision:self.revision
                                                  wiki:wiki];
        }
    }
}

- (NSString*)singleUseUUID {
    return [[NSUUID UUID] UUIDString];
}

- (NSString*)persistentUUID:(NSString*)key {
    NSString* prefKey = [@"EventLoggingID-" stringByAppendingString:key];
    NSString* uuid    = [[NSUserDefaults standardUserDefaults] objectForKey:prefKey];
    if (!uuid) {
        uuid = [self singleUseUUID];
        [[NSUserDefaults standardUserDefaults] setObject:uuid forKey:prefKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return uuid;
}

/**
 *  Persistent random integer id used for sampling.
 *
 *  @return integer sampling id
 */
- (NSInteger)getEventLogSamplingID {
    NSNumber* samplingId = [[NSUserDefaults standardUserDefaults] objectForKey:@"EventLogSamplingID"];
    if (!samplingId) {
        NSInteger intId = arc4random_uniform(UINT32_MAX);
        [[NSUserDefaults standardUserDefaults] setInteger:intId forKey:@"EventLogSamplingID"];
        return intId;
    } else {
        return samplingId.integerValue;
    }
}

@end
