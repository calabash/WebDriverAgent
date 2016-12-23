
#import "XCUIApplication+FBHelpers.h"
#import "XCUIElement+FBFind.h"
#import "FBApplication.h"

#import "CBXQueryCommands.h"
#import "CBXAlertHandler.h"
#import "CBXStringUtils.h"
#import "CBXJSONUtils.h"

@implementation CBXQueryCommands
static NSArray <NSString *> *markedProperties;
static NSArray <NSString *> *textProperties;

+ (NSArray *)routes
{
    return
    @[
      [[FBRoute GET:CBXRoute(@"/springboard-alert")].withCBXSession respondWithTarget:self
                                                                               action:@selector(handleSpringboardAlert:)],
      [[FBRoute POST:CBXRoute(@"/query")].withCBXSession respondWithTarget:self
                                                                   action:@selector(handleQuery:)],
      [[FBRoute GET:CBXRoute(@"/tree")].withCBXSession respondWithTarget:self action:@selector(handleTree:)]
      ];
}

+ (void)load {
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        markedProperties = @[
                             @"identifier",
                             @"accessibilityIdentifier",
                             @"label",
                             @"accessibilityLabel",
                             @"title",
                             @"value",
                             @"placeholderValue"
                             ];
        
        textProperties = @[@"wdLabel",
                           @"wdName",
                           @"wdValue"];
    });
}

+ (NSPredicate *)textPredicate:(NSString *)text {
    return [CBXStringUtils predicateFromKeys:textProperties value:text];
}

+ (NSPredicate *)markedPredicate:(NSString *)mark {
    return [CBXStringUtils predicateFromKeys:textProperties /*TODO: markedProperties. 
                                                             Doesn't work because keys aren't whitelisted by fb*/
                                       value:mark];
}

+ (id<FBResponsePayload>)handleSpringboardAlert:(FBRouteRequest *)request {
    FBAlert *alert = [CBXAlertHandler alertHandler].alert;
    NSArray *results = @[];
    if (alert.springboardAlertIsPresent) {
        results = @[[CBXJSONUtils elementToJSON:alert.springboardAlertElement]];
    }
    return CBXResponseWithJSON(@{@"result" : results});
}

+ (id<FBResponsePayload>)handleQuery:(FBRouteRequest *)request {
    NSDictionary *body = request.arguments;
    FBApplication *application = [FBSession activeSession].application;
    NSArray <XCUIElement *> *elements;
    if ([body hasKey:@"marked"]) {
        elements = [application fb_descendantsMatchingPredicate:[self markedPredicate:body[@"marked"]]
                                    shouldReturnAfterFirstMatch:NO];
    } else if ([body hasKey:@"text"]) {
        elements = [application fb_descendantsMatchingPredicate:[self textPredicate:body[@"text"]]
                                    shouldReturnAfterFirstMatch:NO];
    } else if ([body hasKey:@"id"]) {
        NSString *identifier = body[@"id"];
        elements = [application fb_descendantsMatchingIdentifier:identifier shouldReturnAfterFirstMatch:NO];
    } else if ([body hasKey:@"class"]) {
        NSString *className = body[@"class"];
        elements = [application fb_descendantsMatchingClassName:className shouldReturnAfterFirstMatch:NO];
    }
    elements = [[FBAlert alertWithApplication:application] filterObstructedElements:elements];
    NSMutableArray <NSDictionary *> *json = [NSMutableArray arrayWithCapacity:elements.count];
    for (XCUIElement *el in elements) {
        NSDictionary *elJSON = [CBXJSONUtils elementToJSON:el];
        if (![elJSON hasKey:@"error"]) { //happens if element.exists == NO
            [json addObject:elJSON];
        }
    }
    return CBXResponseWithJSON(@{@"result" : json});
}

+ (id<FBResponsePayload>)handleTree:(FBRouteRequest *)request {
    const BOOL accessibleTreeType = [request.parameters[@"accessible"] boolValue];
    FBApplication *application = [FBSession activeSession].application;
    return FBResponseWithStatus(FBCommandStatusNoError, @{ @"tree": (accessibleTreeType ? application.fb_accessibilityTree : application.fb_tree) ?: @{} } );
}
@end
