//  Created by Monte Hurd on 6/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSURL+Extras.h"
#import "NSString+Extras.h"

@implementation NSURL (Extras)

+ (nullable instancetype)wmf_optionalURLWithString:(nullable NSString*)string {
    return string.length ? [NSURL URLWithString : string] : nil;
}

- (BOOL)wmf_isEqualToIgnoringScheme:(NSURL*)url {
    return [self.wmf_schemelessURLString isEqualToString:url.wmf_schemelessURLString];
}

- (NSString*)wmf_schemelessURLString {
    if (self.scheme.length) {
        return [self.absoluteString wmf_safeSubstringFromIndex:self.scheme.length + 1];
    } else {
        return self.absoluteString;
    }
}

- (NSString*)wmf_mimeTypeForExtension {
    return [self.pathExtension wmf_asMIMEType];
}

- (instancetype)wmf_urlByPrependingSchemeIfSchemeless:(NSString*)scheme {
    NSParameterAssert(scheme.length);
    if (self.scheme.length) {
        return self;
    } else {
        NSURLComponents* components = [[NSURLComponents alloc] initWithURL:self resolvingAgainstBaseURL:YES];
        components.scheme = scheme;
        return components.URL;
    }
}

- (instancetype)wmf_urlByPrependingSchemeIfSchemeless {
    return [self wmf_urlByPrependingSchemeIfSchemeless:@"https"];
}

- (NSString*)wmf_valueForQueryKey:(NSString*)queryKey {
    NSURLQueryItem* queryItem = [[[NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES] queryItems]
                                 bk_match:^BOOL (NSURLQueryItem* q) {
        return [q.name isEqualToString:@"page"];
    }];
    return queryItem ? (queryItem.value ? : @"") : nil;
}

- (BOOL)wmf_isIntraPageFragment {
    return ([self.path isEqualToString:@"/"] && self.fragment);
}

@end
