
#import "CBXStringUtils.h"

@implementation CBXStringUtils
static NSDictionary<NSString *, NSString *> *escapeMap;
+ (void)load {
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        NSArray<NSString *> *array;
        // I experimented with this set of items, but after several crashes
        // I decided to not bother with the more esoteric control characters.
        //
        // array = @[@"\0", @"\a", @"\b", @"\t", @"\n", @"\f", @"\r", @"\e", @"\'"];
        //
        // I was also worried about "%" as it is a format character, but it
        // appears it needs no special handling.
        array = @[@"\n", @"\t", @"'", @"\""];
        NSMutableDictionary<NSString *, NSString *> *mutable;
        mutable = [NSMutableDictionary dictionaryWithCapacity:[array count]];
        
        NSString *value;
        for (NSString *key in array) {
            value = [NSString stringWithFormat:@"\\%@", key];
            mutable[key] = value;
        }
        
        escapeMap = [NSDictionary dictionaryWithDictionary:mutable];
    });
}

+ (NSString *)escapeString:(NSString *)string {
    NSMutableString *mutable = [[NSMutableString alloc] initWithString:string];
    [escapeMap enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        // Assume that if the string already contains the escape sequence
        // is already present, the string is already escaped.  See the
        // cucumber/features/query.feature.
        if (![mutable containsString:value]) {
            NSRange range = NSMakeRange(0, [mutable length]);
            [mutable replaceOccurrencesOfString:key
                                     withString:value
                                        options:NSCaseInsensitiveSearch
                                          range:range];
        }
    }];
    return [NSString stringWithString:mutable];
}

+ (NSPredicate *)predicateFromKeys:(NSArray <NSString *> *)keys value:(NSString *)value {
    /*
     TODO: Performance win with NSCompoundPredicate?
     
     JJM: I tried NSCompoundPredicate and I consistently got no results.  My best
     guess is that XCUIElementQuery does not respond to compound predicates.
     
     We could try NSPredicate predicateWithBlock:, but my guess is that this will
     not work.
     
     Recall that CoreData does not allow block predicates, so there is some
     precedence for restricting NSPredicate kinds (?) in certain contexts.
     
     NOTE: Using == here is appropriate.  LIKE responds to the ? character which
     will be a problem if the value contains a ?.
     */
    NSString *escaped = [CBXStringUtils escapeString:value];
    NSMutableString *predicateString = [NSMutableString string];
    for (NSString *prop in keys) {
        [predicateString appendFormat:@"%@ == '%@'", prop, escaped];
        if (prop != [keys lastObject]) {
            [predicateString appendString:@" OR "];
        }
    }
    return [NSPredicate predicateWithFormat:predicateString];
}

@end
