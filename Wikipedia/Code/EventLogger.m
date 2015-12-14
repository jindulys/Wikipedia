//  Created by Monte Hurd on 4/11/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "EventLogger.h"
#import "NSString+Extras.h"
#import "WikipediaAppUtils.h"

NSString* const WMFLoggingEndpoint =
    // production
    @"https://meta.wikimedia.org/beacon/event";
// testing
// @"http://deployment.wikimedia.beta.wmflabs.org/beacon/event";

@implementation EventLogger

- (instancetype)initAndLogEvent:(NSDictionary*)event
                      forSchema:(NSString*)schema
                       revision:(int)revision
                           wiki:(NSString*)wiki {
    self = [super init];
    if (self) {
        if (event && schema && wiki) {
            NSDictionary* payload =
                @{
                @"event": event,
                @"revision": @(revision),
                @"schema": schema,
                @"wiki": wiki
            };

            NSData* payloadJsonData     = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
            NSString* payloadJsonString = [[NSString alloc] initWithData:payloadJsonData encoding:NSUTF8StringEncoding];
            //NSLog(@"%@", payloadJsonString);
            NSString* encodedPayloadJsonString = [payloadJsonString wmf_UTF8StringWithPercentEscapes];
            NSString* urlString                = [NSString stringWithFormat:@"%@?%@;", WMFLoggingEndpoint, encodedPayloadJsonString];
            NSMutableURLRequest* request       = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
            [request addValue:[WikipediaAppUtils versionedUserAgent] forHTTPHeaderField:@"User-Agent"];
            // arguably, we don't need to add the UUID to these requests
            /*
               ReadingActionFunnel *funnel = [[ReadingActionFunnel alloc] init];
               [manager.requestSerializer setValue:funnel.appInstallID forHTTPHeaderField:@"X-WMF-UUID"];
             */

            (void)[[NSURLConnection alloc] initWithRequest:request delegate:nil];
        }
    }
    return self;
}

@end
