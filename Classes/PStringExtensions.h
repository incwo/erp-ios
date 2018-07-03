//
//  PStringExtensions.h
//
//

#import <Foundation/Foundation.h>
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif


@interface NSString(PStringExtensions)
- (NSString*) stringByKeepingCharactersInSet:(NSCharacterSet*)set;
- (NSString*) stringByRemovingCharactersInSet:(NSCharacterSet*)set;
- (NSString*) stringByEscapingXMLEntities;
- (NSString*) stringByUnescapingExtendedCharacters; // unavailable because this selector doesn't mean anything
- (NSString*) md5HexDigest;
- (NSInteger) hexValue;


/* Path routines */
- (NSString*) pathByRemovingQueryString;

/* HTML routines */
- (NSString*) stringByResolvingHTMLEntities;
- (NSString*) stringByAddingPercentEscapesToSpaces;
- (NSUInteger) indexOfCharacterInString:(char)ch afterIndex:(NSUInteger)startIndex;

/*
	returns a font with same fontname as font, and no bigger than it, so the receiver drawn with it fits (is smaller than) size.
	It it is impossible, return nil.
 */
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
- (UIFont*) fontThatFits:(CGSize)size withFont:(UIFont*)font;
#endif

@end
