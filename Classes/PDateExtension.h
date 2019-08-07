//
//  PDateExtension.h
//
//

#import <Foundation/Foundation.h>


@interface NSDate (PExtensions)
// A HTTP date can be found in HTTP headers ("Last-Modified" = "Fri, 18 Jul 2008 13:45:50 GMT";)
+ (NSDate*) dateWithHTTPDate:(NSString*)httpDate;
- (NSString*) httpDateString;

@end
