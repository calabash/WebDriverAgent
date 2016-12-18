/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBResponsePayload.h"

#import "FBElementCache.h"
#import "FBResponseFilePayload.h"
#import "FBResponseJSONPayload.h"
#import "FBSession.h"

#import "XCUIElement+FBWebDriverAttributes.h"

inline static NSDictionary *FBDictionaryResponseWithElement(XCUIElement *element, NSString *elementUUID, BOOL compact);

id<FBResponsePayload> FBResponseWithOK()
{
  return FBResponseWithStatus(FBCommandStatusNoError, nil);
}

id<FBResponsePayload> FBResponseWithObject(id object)
{
  return FBResponseWithStatus(FBCommandStatusNoError, object);
}

id<FBResponsePayload> FBResponseWithCachedElement(XCUIElement *element, FBElementCache *elementCache)
{
  NSString *elementUUID = [elementCache storeElement:element];
  return FBResponseWithStatus(FBCommandStatusNoError, FBDictionaryResponseWithElement(element, elementUUID, NO));
}

id<FBResponsePayload> FBResponseWithCachedElements(NSArray<XCUIElement *> *elements, FBElementCache *elementCache, BOOL compact)
{
  NSMutableArray *elementsResponse = [NSMutableArray array];
  for (XCUIElement *element in elements) {
    NSString *elementUUID = [elementCache storeElement:element];
    [elementsResponse addObject:FBDictionaryResponseWithElement(element, elementUUID, compact)];
  }
  return FBResponseWithStatus(FBCommandStatusNoError, elementsResponse);
}

id<FBResponsePayload> FBResponseWithElementUUID(NSString *elementUUID)
{
  return [[FBResponseJSONPayload alloc] initWithDictionary:@{
    @"id" : elementUUID,
    @"sessionId" : [FBSession activeSession].identifier ?: NSNull.null,
    @"value" : @"",
    @"status" : @0,
  }];
}

id<FBResponsePayload> FBResponseWithError(NSError *error)
{
  return FBResponseWithStatus(FBCommandStatusUnhandled, error.description);
}

id<FBResponsePayload> FBResponseWithErrorFormat(NSString *format, ...)
{
  va_list argList;
  va_start(argList, format);
  NSString *errorMessage = [[NSString alloc] initWithFormat:format arguments:argList];
  id<FBResponsePayload> payload = FBResponseWithStatus(FBCommandStatusUnhandled, errorMessage);
  va_end(argList);
  return payload;
}

id<FBResponsePayload> FBResponseWithStatus(FBCommandStatus status, id object)
{
    NSMutableDictionary *resp = [@{
                                  @"value" : object ?: @{},
                                  @"sessionId" : [FBSession activeSession].identifier ?: NSNull.null,
                                  @"status" : @(status),
                                  } mutableCopy];
    if (status != FBCommandStatusNoError) {
        resp[@"error"] = @"Unhandled Route";
    }
  return [[FBResponseJSONPayload alloc] initWithDictionary:resp];
}

/**
 Returns @{@"error" : error.localizedDescription, @"info" : info}
 */
id<FBResponsePayload> CBXResponseWithError(NSError *error) {
    return [[FBResponseJSONPayload alloc] initWithDictionary:@{
       @"error" : error.localizedDescription,
    }];
}

id<FBResponsePayload> CBXResponseWithException(NSException *exc) {
    return [[FBResponseJSONPayload alloc] initWithDictionary:@{
                                                               @"error" : exc.name ?: @"",
                                                               @"reason" : exc.reason ?: @"",
                                                               @"info" : exc.userInfo ?: @{}
                                                               }];
}


id<FBResponsePayload> CBXResponseWithErrorFormat(NSString *format, ...)
{
    va_list argList;
    va_start(argList, format);
    NSString *errorMessage = [[NSString alloc] initWithFormat:format arguments:argList];
    id<FBResponsePayload> payload = CBXResponseWithJSON(@{@"error" : errorMessage});
    va_end(argList);
    return payload;
}

/**
 Returns 'status' response payload with given object
 */
id<FBResponsePayload> CBXResponseWithStatus(NSString *status, id object) {
    return CBXResponseWithJSON(@{
       @"info" : object ?: @{},
       @"status" : status,
    });
}

id<FBResponsePayload> CBXResponseWithJSON(NSDictionary *json) {
    return [[FBResponseJSONPayload alloc] initWithDictionary:json];
}

id<FBResponsePayload> FBResponseFileWithPath(NSString *path)
{
  return [[FBResponseFilePayload alloc] initWithFilePath:path];
}

inline static NSDictionary *FBDictionaryResponseWithElement(XCUIElement *element, NSString *elementUUID, BOOL compact)
{
  NSMutableDictionary *dictionary = [NSMutableDictionary new];
  dictionary[@"ELEMENT"] = elementUUID;
  if (!compact) {
    dictionary[@"type"] = element.wdType;
    dictionary[@"label"] = element.wdLabel ?: [NSNull null];
  }
  return dictionary.copy;
}
