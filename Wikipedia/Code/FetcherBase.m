//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "FetcherBase.h"
#import "SessionSingleton.h"

@implementation FetcherBase

- (void)finishWithError:(NSError*)error
            fetchedData:(id)fetchedData {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self setConnectionManagementFallbackForError:error];
        //TODO: this could also be a good place to log error.domain string and error.code?

        [self.fetchFinishedDelegate fetchFinished:self
                                      fetchedData:fetchedData
                                           status:[self getStatusFromError:error]
                                            error:error];
    }];
}

- (FetchFinalStatus)getStatusFromError:(NSError*)error {
    // Examine error to see what status should be used.
    // Nice as it eliminates lots of repeated code.
    FetchFinalStatus status = FETCH_FINAL_STATUS_SUCCEEDED;
    if (error) {
        status = FETCH_FINAL_STATUS_FAILED;
        if ([error.domain isEqualToString:NSURLErrorDomain]) {
            if (error.code == NSURLErrorCancelled) {
                status = FETCH_FINAL_STATUS_CANCELLED;
            }
        }
    }
    return status;
}

- (void)setConnectionManagementFallbackForError:(NSError*)error {
    if (error.domain == NSStreamSocketSSLErrorDomain ||
        (error.domain == NSURLErrorDomain &&
         (error.code == NSURLErrorSecureConnectionFailed ||
          error.code == NSURLErrorServerCertificateHasBadDate ||
          error.code == NSURLErrorServerCertificateUntrusted ||
          error.code == NSURLErrorServerCertificateHasUnknownRoot ||
          error.code == NSURLErrorServerCertificateNotYetValid)
         //error.code == NSURLErrorCannotLoadFromNetwork) //TODO: check this out later?
        )
        ) {
        [SessionSingleton sharedInstance].fallback = true;
    }
}

- (BOOL)isDataResponseValid:(id)responseObject {
    return !(
        !responseObject
        ||
        ![responseObject isKindOfClass:[NSData class]]
        ||
        ([responseObject length] == 0)
        ||
        ([responseObject length] == 2)      // Protect against query returning "[]".
        );
}

- (NSDictionary*)dictionaryFromDataResponse:(id)responseObject {
    NSDictionary* output = nil;
    // Convert the raw NSData response to a dictionary.
    if (![self isDataResponseValid:responseObject]) {
        // Fake out an error if bad response received.
        output = @{@"error": @{@"info": @"Dictionary data not found."}};
    } else {
        // Should be able to proceed with dictionary conversion.
        NSError* jsonError = nil;
        NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:responseObject
                                                             options:0
                                                               error:&jsonError];
        output = jsonError ? @{} : dict;
    }
    return output;
}

@end
