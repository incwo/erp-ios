//
//  PXWWWFormSerialization.m
//
//

#import "PXWWWFormSerialization.h"

@interface PXWWWFormSerialization()
+ (NSString *)stringByDecodingURLFormat:(NSString *)string;
+ (NSString *)stringByEncodingURLFormat:(NSString *)string;
@end

@implementation PXWWWFormSerialization

+ (NSDictionary *)dictionaryWithURL:(NSURL *)URL options:(PXWWWFormDecodingOptions)options
{
    return [self dictionaryWithString:URL.query options:options];
}

+ (NSDictionary *)dictionaryWithString:(NSString *)string options:(PXWWWFormDecodingOptions)options
{
    if (string.length == 0) {
        return [NSDictionary dictionary];
    }
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (NSString *keyValueString in [string componentsSeparatedByString:@"&"]) {
        
        NSArray *keyValueArray = [keyValueString componentsSeparatedByString:@"="];
        switch (keyValueArray.count) {
            case 1: {
                if (options & PXWWWFormDecodingMissingValueWithYES) {
                    NSString *key = [self stringByDecodingURLFormat:keyValueArray[0]];
                    if (dictionary[key]) {
                        // Don't raise, so that external URLs does not break the application.
                        // Log instead.
                        NSLog(@"Support for multiple values is not implemented (key %@): %@", key, string);
                        return nil;
                    }
                    dictionary[key] = @YES;
                } else {
                    // Don't raise, so that external URLs does not break the application.
                    // Log instead.
                    NSLog(@"Decoding a key (%@) without value requires a decoding option", [self stringByDecodingURLFormat:keyValueArray[0]]);
                    return nil;
                }
            } break;
                
            case 2: {
                NSString *key = [self stringByDecodingURLFormat:keyValueArray[0]];
                NSString *value = [self stringByDecodingURLFormat:keyValueArray[1]];
                
                if (dictionary[key]) {
                    // Don't raise, so that external URLs does not break the application.
                    // Log instead.
                    NSLog(@"Support for multiple values is not implemented (key %@): %@", key, string);
                    return nil;
                }
                dictionary[key] = value;
            } break;
                
            default:
                // Don't raise, so that external URLs does not break the application.
                // Log instead.
                NSLog(@"Invalid x-www-form encoded string: %@", string);
                return nil;
        }
    }
    
    return dictionary;
}

+ (NSString *)stringWithDictionary:(NSDictionary *)dictionary options:(PXWWWFormEncodingOptions)options
{
    NSMutableArray *components = [NSMutableArray array];
    [self enumerateKeysAndValuesWithDictionary:dictionary options:options usingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        NSString *encodedKey = [self stringByEncodingURLFormat:key];
        NSString *encodedValue = [self stringByEncodingURLFormat:[value description]];
        [components addObject:[NSString stringWithFormat:@"%@=%@", encodedKey, encodedValue]];
    }];
    return [components componentsJoinedByString:@"&"];
}

+ (void)enumerateKeysAndValuesWithDictionary:(NSDictionary *)dictionary options:(PXWWWFormEncodingOptions)options usingBlock:(void(^)(NSString *key, NSString *value, BOOL *stop))block
{
    BOOL stop = NO;
    for(NSString *key in [dictionary allKeys]) {
        if (![key isKindOfClass:[NSString class]]) {
            [NSException raise:NSInvalidArgumentException format:@"Invalid (non-string) key: %@", key];
        }
        
        id value = dictionary[key];
        if ([value isKindOfClass:[NSString class]])
        {
            block(key, value, &stop);
            if (stop) return;
        }
        else if ([value isKindOfClass:[NSArray class]])
        {
            if (options & PXWWWFormEncodingArrayByRepeatingKey) {
                for (id value2 in value) {
                    if ([value2 isKindOfClass:[NSString class]])
                    {
                        block(key, value2, &stop);
                        if (stop) return;
                    }
                    else {
                        [NSException raise:NSInvalidArgumentException format:@"Not impletemented: support for array values containing %@ objects (key %@)", [value2 class], key];
                    }
                }
            } else {
                [NSException raise:NSInvalidArgumentException format:@"Encoding NSArray values (key %@) requires an NSArray encoding options", key];
            }
        }
        else {
            // It's undecided (yet) how we should encode special objects
            [NSException raise:NSInvalidArgumentException format:@"Support for %@ values is not implemented (key %@): %@", [value class], key, value];
        }
    }
}


//

+ (NSString *)stringByDecodingURLFormat:(NSString *)string
{
    // decode '+', then percents
    NSString *result = [string stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByRemovingPercentEncoding];
    return result;
}

+ (NSString *)stringByEncodingURLFormat:(NSString *)string
{
    // NSString does part of the job.
    string = [string stringByRemovingPercentEncoding];
    
    NSUInteger length = [string length];
    if (length == 0) {
        return string;
    }
    
    // We need more encoding
    static const NSString *escapeForCharacter[] = {
        ['$'] = @"%24",
        ['&'] = @"%26",
        ['+'] = @"%2B",
        [','] = @"%2C",
        ['/'] = @"%2F",
        [':'] = @"%3A",
        [';'] = @"%3B",
        ['='] = @"%3D",
        ['?'] = @"%3F",
        ['@'] = @"%40",
#if !defined(__IPHONE_OS_VERSION_MIN_REQUIRED) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
        // Those are already processed by [NSString stringByAddingPercentEscapesUsingEncoding:] on iOS >= 6
        // TODO: check if there is a single platform we may target that requires those extra encoding checks.
        [' '] = @"%20",
        ['\t'] = @"%09",
        ['#'] = @"%23",
        ['<'] = @"%3C",
        ['>'] = @"%3E",
        ['\"'] = @"%22",
        ['\n'] = @"%0A",
#endif
    };
    static const int escapeForCharacterLength = sizeof(escapeForCharacter) / sizeof(NSString *);
    
    
    // Assume most strings don't need more escaping, and help performances: avoid
    // creating a NSMutableData instance if escaping in uncessary.
    
    CFIndex unescapedLength = 0;
    for (NSUInteger i=0; i<length; ++i) {
        unichar character = [string characterAtIndex:i];
        if (character < escapeForCharacterLength && escapeForCharacter[character]) {
            unescapedLength = i;
            break;
        }
    }
    
    if (unescapedLength == 0) {
        return string;
    }
    
    
    // Escape
    
    const UniChar *characters = CFStringGetCharactersPtr((CFStringRef)string);
    if (!characters) {
        NSMutableData *data = [NSMutableData dataWithLength:length * sizeof(UniChar)];  // autoreleased
        [string getCharacters:[data mutableBytes] range:(NSRange){ .location = 0, .length = length }];
        characters = [data bytes];
    }
    
    NSMutableString *buffer = [NSMutableString stringWithCapacity:length];
    const UniChar *unescapedStart = characters;
    characters += unescapedLength;
    for (NSUInteger i=unescapedLength; i<length; ++i, ++characters) {
        const NSString *escape = (*characters < escapeForCharacterLength) ? escapeForCharacter[*characters] : nil;
        if (escape) {
            CFStringAppendCharacters((CFMutableStringRef)buffer, unescapedStart, unescapedLength);
            CFStringAppend((CFMutableStringRef)buffer, (CFStringRef)escape);
            unescapedStart = characters+1;
            unescapedLength = 0;
        } else {
            ++unescapedLength;
        }
    }
    if (unescapedLength > 0) {
        CFStringAppendCharacters((CFMutableStringRef)buffer, unescapedStart, unescapedLength);
    }
    return buffer;
}

@end
