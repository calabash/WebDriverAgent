
#import <Foundation/Foundation.h>

@interface CBXStringUtils : NSObject
+ (NSString *)escapeString:(NSString *)string;
+ (NSPredicate *)predicateFromKeys:(NSArray <NSString *> *)keys value:(NSString *)value;
@end
