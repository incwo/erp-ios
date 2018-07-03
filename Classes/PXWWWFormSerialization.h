//
//  PXWWWFormSerialization.h
//
//

#import <Foundation/Foundation.h>

enum {
    // NSArray encoding options
    PXWWWFormEncodingArrayByRepeatingKey = (1UL << 0),   // Repeat keys associated to arrays; @{ @"foo": @[@"a",@"b"] } -> @"foo=a&foo=b"
};
typedef NSUInteger PXWWWFormEncodingOptions;

enum {
    // Missing value decoding options
    PXWWWFormDecodingMissingValueWithYES = (1UL << 0),   // Turn missing values into @YES; @"foo=1&bar" -> @{ @"foo": @"1", @"bar": @YES }
};
typedef NSUInteger PXWWWFormDecodingOptions;

@interface PXWWWFormSerialization : NSObject

// Turns an NSURL query into a dictionary:
// http://domain.com/path?foo=1&bar=2 => @{ @"foo": @"1", @"bar": @"2" }
+ (NSDictionary *)dictionaryWithURL:(NSURL *)URL options:(PXWWWFormDecodingOptions)options;

// Turns a query string into a dictionary:
// @"foo=1&bar=2" => @{ @"foo": @"1", @"bar": @"2" }
+ (NSDictionary *)dictionaryWithString:(NSString *)string options:(PXWWWFormDecodingOptions)options;

// Turns a dictionary into a query:
// @{ @"foo": @"1", @"bar": @"2" } => @"foo=1&bar=2"
+ (NSString *)stringWithDictionary:(NSDictionary *)dictionary options:(PXWWWFormEncodingOptions)options;

@end
