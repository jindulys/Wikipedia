//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "CaptchaResetter.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"

@interface CaptchaResetter ()

@property (strong, nonatomic) NSString* domain;

@end

@implementation CaptchaResetter

- (instancetype)initAndResetCaptchaForDomain:(NSString*)domain
                                 withManager:(AFHTTPRequestOperationManager*)manager
                          thenNotifyDelegate:(id <FetchFinishedDelegate>)delegate {
    self = [super init];
    if (self) {
        self.domain                = domain ? domain : @"";
        self.fetchFinishedDelegate = delegate;
        [self resetCaptchaWithManager:manager];
    }
    return self;
}

- (void)resetCaptchaWithManager:(AFHTTPRequestOperationManager*)manager {
    NSURL* url = [[SessionSingleton sharedInstance] urlForLanguage:self.domain];

    NSDictionary* params = [self getParams];

    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager POST:url.absoluteString parameters:params success:^(AFHTTPRequestOperation* operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        // Fake out an error if non-dictionary response received.
        if (![responseObject isDict]) {
            responseObject = @{@"error": @{@"info": @"Captcha Resetter data not found."}};
        }

        //NSLog(@"CAPTCHA RESETTER DATA RETRIEVED = %@", responseObject);

        // Handle case where response is received, but API reports error.
        NSError* error = nil;
        if (responseObject[@"error"]) {
            NSMutableDictionary* errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain:@"Captcha Resetter"
                                        code:CAPTCHA_RESET_ERROR_API
                                    userInfo:errorDict];
        }

        NSDictionary* output = @{};
        if (!error) {
            output = [self getSanitizedResponse:responseObject];
        }

        [self finishWithError:error
                  fetchedData:output];
    } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        //NSLog(@"CAPTCHA RESETTER FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError:error
                  fetchedData:nil];
    }];
}

- (NSDictionary*)getParams {
    return @{
               @"action": @"fancycaptchareload",
               @"format": @"json"
    };
}

- (NSDictionary*)getSanitizedResponse:(NSDictionary*)rawResponse {
    NSDictionary* response = @{};
    if ([rawResponse isDict]) {
        response = rawResponse[@"fancycaptchareload"];
    }
    return response;
}

+ (NSString*)newCaptchaImageUrlFromOldUrl:(NSString*)oldUrl andNewId:(NSString*)newId {
    NSError* error             = nil;
    NSRegularExpression* regex =
        [NSRegularExpression regularExpressionWithPattern:@"wpCaptchaId=([^&]*)"
                                                  options:NSRegularExpressionCaseInsensitive
                                                    error:&error];
    if (!error) {
        NSString* newCaptchaUrl =
            [regex stringByReplacingMatchesInString:oldUrl
                                            options:0
                                              range:NSMakeRange(0, [oldUrl length])
                                       withTemplate:[NSString stringWithFormat:@"wpCaptchaId=%@", newId]];

        return newCaptchaUrl;
    }
    return nil;
}

@end
