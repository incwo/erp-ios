//
//  PStringExtensions.h
//
//

#import <Foundation/Foundation.h>

@interface NSString(PStringExtensions)
- (NSString*) stringByUnescapingExtendedCharacters; // unavailable because this selector doesn't mean anything
- (NSInteger) hexValue;


/* Path routines */
- (NSString*) pathByRemovingQueryString;

/* HTML routines */
- (NSString*) stringByResolvingHTMLEntities;
- (NSString*) stringByAddingPercentEscapesToSpaces;

@end
