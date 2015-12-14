
#import "WMFLocalization.h"
#import "MWKSite.h"

NSString* localizedStringForKeyFallingBackOnEnglish(NSString* key){
    NSString* outStr = NSLocalizedString(key, nil);
    if (![outStr isEqualToString:key]) {
        return outStr;
    }

    static NSBundle* englishBundle = nil;

    if (!englishBundle) {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"];
        englishBundle = [NSBundle bundleWithPath:path];
    }
    return [englishBundle localizedStringForKey:key value:@"" table:nil];
}

NSString* localizedStringForSiteWithKeyFallingBackOnEnglish(MWKSite* site, NSString* key){
    NSString* path           = [[NSBundle mainBundle] pathForResource:site.language ofType:@"lproj"];
    NSBundle* languageBundle = [NSBundle bundleWithPath:path];
    NSString* translation    = nil;
    if (languageBundle) {
        translation = [languageBundle localizedStringForKey:key value:@"" table:nil];
    }
    if (!translation || [translation isEqualToString:key] || (translation.length == 0)) {
        return MWLocalizedString(key, nil);
    }
    return translation;
}

