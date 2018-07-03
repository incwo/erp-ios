//
//  PDateExtension.m
//
//

#import "PDateExtension.h"


@implementation NSDate (PExtensions)


//"Fri, 18 Jul 2008 13:45:50 GMT"
// see http://rel.me/2008/07/22/date-format-rfc82285010361123asctimeiso8601unicode35tr35-6/
+(NSDate*) dateWithHTTPDate:(NSString*)httpDate
{
	/*
	 iOS 4.2: NSDate is leaked from this method when option "z" (time zone) is used.
	 
	 See http://stackoverflow.com/questions/1117263/instruments-leaks-and-nsdateformatter
	 
	 Quote:	 
	 There may be a problem with NSDateFormatter parsing date strings with time zones because when I changed the formatter pattern to remove the timezone portion the problem disappeared.
	 
	 I changed it from this:
	 
	 [df setDateFormat:@"EEE, d MMM yyyy H:m:s z"];
	 
	 To this:
	 
	 [df setDateFormat:@"EEE, d MMM yyyy H:m:s"];
	 
	 But now the problem is the dates don't get the right timezone so I'll have to have to determine the timezone myself.
	 */
	
	NSDate* date = nil;
	if (httpDate == nil) {
        return nil;
    }
    
    NSDateFormatter *dateFormatter = [[[NSThread currentThread] threadDictionary] objectForKey:@"PDateExtension_dateWithHTTPDateFormatter"];
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
        [[[NSThread currentThread] threadDictionary] setObject:dateFormatter forKey:@"PDateExtension_dateWithHTTPDateFormatter"];
        //[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        // TODO : handle timezone correctly
    }
    
    [dateFormatter setDateFormat:@"EEE, d MMM yy HH:mm:ss zzz"]; // RFC822: Sun, 19 May 02 15:21:36 GMT
    date = [dateFormatter dateFromString:httpDate];
    if (date) return date;

    [dateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss zzz"]; // RFC822: Sun, 19 May 2002 15:21:36 GMT
    date = [dateFormatter dateFromString:httpDate];
    if (date) return date;
    
    [dateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm zzz"];  // RFC822: Sun, 19 May 2002 15:21 GMT
    date = [dateFormatter dateFromString:httpDate];
    if (date) return date;
    
    [dateFormatter setDateFormat:@"d MMM yyyy HH:mm:ss zzz"];  // RFC822: 19 May 2002 15:21:36 GMT
    date = [dateFormatter dateFromString:httpDate];
    if (date) return date;
    
    [dateFormatter setDateFormat:@"d MMM yyyy HH:mm zzz"];  // RFC822: 19 May 2002 15:21 GMT
    date = [dateFormatter dateFromString:httpDate];
    if (date) return date;
    
    [dateFormatter setDateFormat:@"d MMM yyyy HH:mm:ss"];  // RFC822: 19 May 2002 15:21:36
    date = [dateFormatter dateFromString:httpDate];
    if (date) return date;
    
    [dateFormatter setDateFormat:@"d MMM yyyy HH:mm"];  // RFC822: 19 May 2002 15:21
    date = [dateFormatter dateFromString:httpDate];
    if (date) return date;
    
    [dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
    date = [dateFormatter dateFromString:httpDate];
    if (date) return date;
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'"];
    date = [dateFormatter dateFromString:httpDate];
    if (date) return date;
    
    // We now want to parse 2009-01-13T07:54:16 style date
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:sszzz'"];
    date = [dateFormatter dateFromString:httpDate];
    if (date) return date;
    
    // We now want to parse 2009-01-13T07:54:16Z style date
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    date = [dateFormatter dateFromString:httpDate];
    if (date) return date;
    
    [dateFormatter setDateFormat:@"MMM dd yyyy HH:mm:ss'"];
    date = [dateFormatter dateFromString:httpDate];
    if (date) return date;
    
    [dateFormatter setDateFormat:@"dd MMM yyyy HH:mm:ss zzz'"];
    date = [dateFormatter dateFromString:httpDate];
    if (date) return date;
    
    [dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss' +'zzz'"];
    date = [dateFormatter dateFromString:httpDate];
    if (date) return date;
    
    // We now want to parse 2009-01-13T07:54:16Z style date
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'+'Z"];
    date = [dateFormatter dateFromString:httpDate];
    if (date) return date;
    
    // We now want to parse HH:mm format
    [dateFormatter setDateFormat:@"HH:mm"];
    date = [dateFormatter dateFromString:httpDate];
    if (date) return date;
    
    // We now want to parse 2009-01-13T07:54:16+00:00 style date.
    // It is buggy, but let's try nonetheless (Facebook uses it)
    {
        NSUInteger plusLocation = [httpDate rangeOfString:@"+"].location;
        if (plusLocation != NSNotFound)
        {
            NSString* datePart = [httpDate substringToIndex:plusLocation];
            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'"];
            date = [dateFormatter dateFromString:datePart];
            if (date) return date;
        }
    }
    
    // We now want to parse Sat, 7 Aug 2010 16:50:00 ++01:00 style date.
    // It is buggy, but let's try nonetheless (a client does use it)
    {
        NSUInteger plusLocation = [httpDate rangeOfString:@"++"].location;
        if (plusLocation != NSNotFound)
        {
            NSString* datePart = [httpDate substringToIndex:plusLocation];
            [dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss"];
            date = [dateFormatter dateFromString:datePart];
            if (date) return date;
        }
    }

    NSLog(@"dateWithHTTPDate failed to parse %@", httpDate);
	return nil;
}

- (NSString*) httpDateString
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
	[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	[dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
	return [dateFormatter stringFromDate:self];
}


+(BOOL) resourceWithClientDate:(NSDate*)clientDate requiresUpdateConsideringHeaders:(NSDictionary*)headers
{
	// If no headers, we consider we cant decide, so we require update.
	// If no client date, we consider we have no cache, so we require update.
	if (headers == nil || clientDate == nil) return YES;
	
	NSString* lastModifiedHeader = [headers objectForKey:@"Last-Modified"];
	
	// If no last-modified headers, we cant decide, so we require update
	if (lastModifiedHeader == nil) return YES;
	
	// Our client date is later than our server date ? No update needed. Otherwise update !
	NSDate* serverDate = [NSDate dateWithHTTPDate:lastModifiedHeader];
	if (serverDate && [serverDate compare:clientDate] == NSOrderedAscending)
		return NO;
	return YES;
}
@end
