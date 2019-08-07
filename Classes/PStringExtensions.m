//
//  PStringExtensions.m
//
//

#import "PStringExtensions.h"

NSArray* gNSStringPStringExtensionsHTMLEntities = nil;

@interface NSString(PStringPrivateExtensions)
+ (NSString *) privateMapEntityToString:(NSString *)entityString;
@end

@implementation NSString(PStringExtensions)

+ (NSArray*) htmlEntities
{
	if (gNSStringPStringExtensionsHTMLEntities == nil)
		gNSStringPStringExtensionsHTMLEntities = [[NSArray alloc] initWithObjects: /*@"&amp;", @"&lt;", @"&gt;", @"&quot;",*/
												  @"&nbsp;", @"&iexcl;", @"&cent;", @"&pound;", @"&curren;", @"&yen;", @"&brvbar;",
												  @"&sect;", @"&uml;", @"&copy;", @"&ordf;", @"&laquo;", @"&not;", @"&shy;", @"&reg;",
												  @"&macr;", @"&deg;", @"&plusmn;", @"&sup2;", @"&sup3;", @"&acute;", @"&micro;",
												  @"&para;", @"&middot;", @"&cedil;", @"&sup1;", @"&ordm;", @"&raquo;", @"&frac14;",
												  @"&frac12;", @"&frac34;", @"&iquest;", @"&Agrave;", @"&Aacute;", @"&Acirc;",
												  @"&Atilde;", @"&Auml;", @"&Aring;", @"&AElig;", @"&Ccedil;", @"&Egrave;",
												  @"&Eacute;", @"&Ecirc;", @"&Euml;", @"&Igrave;", @"&Iacute;", @"&Icirc;", @"&Iuml;",
												  @"&ETH;", @"&Ntilde;", @"&Ograve;", @"&Oacute;", @"&Ocirc;", @"&Otilde;", @"&Ouml;",
												  @"&times;", @"&Oslash;", @"&Ugrave;", @"&Uacute;", @"&Ucirc;", @"&Uuml;", @"&Yacute;",
												  @"&THORN;", @"&szlig;", @"&agrave;", @"&aacute;", @"&acirc;", @"&atilde;", @"&auml;",
												  @"&aring;", @"&aelig;", @"&ccedil;", @"&egrave;", @"&eacute;", @"&ecirc;", @"&euml;",
												  @"&igrave;", @"&iacute;", @"&icirc;", @"&iuml;", @"&eth;", @"&ntilde;", @"&ograve;",
												  @"&oacute;", @"&ocirc;", @"&otilde;", @"&ouml;", @"&divide;", @"&oslash;", @"&ugrave;",
												  @"&uacute;", @"&ucirc;", @"&uuml;", @"&yacute;", @"&thorn;", @"&yuml;", nil];
	
	return gNSStringPStringExtensionsHTMLEntities;
}

- (NSInteger) hexValue
{
	NSUInteger count = [self length];
	NSInteger intValue = 0;
	NSInteger index = 0;
	
	while (index < count)
	{
		unichar ch = [self characterAtIndex:index];
		if (ch >= '0' && ch <= '9')
			intValue = (intValue * 16) + (ch - '0');
		else if (ch >= 'A' && ch <= 'F')
			intValue = (intValue * 16) + (ch - 'A' + 10);
		else if (ch >= 'a' && ch <= 'f')
			intValue = (intValue * 16) + (ch - 'a' + 10);
		else
			break;
		++index;
	}
	return intValue;
}

- (NSString*) stringByAddingPercentEscapesToSpaces
{
	// NSLog(@"url: %@", [@" \t\n\r\v" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
	// url: %20%09%0A%0D%0B
	
	return [[self
			 stringByReplacingOccurrencesOfString:@" " withString:@"%20"] 
			stringByReplacingOccurrencesOfString:@"\t" withString:@"%09"];
}


- (NSString*) stringByResolvingHTMLEntities
{
    NSMutableString* result = [NSMutableString stringWithString:self];
	CFStringTransform((CFMutableStringRef) result, NULL, CFSTR("Hex-Any"), NO);
	
	if (	[(NSString*) result rangeOfString:@"&"].location != NSNotFound
		&&	[(NSString*) result rangeOfString:@";"].location != NSNotFound)
	{
		// String may still contains html characters, remove them
		NSArray* htmlEntities = [NSString htmlEntities];
		NSUInteger i, count = [htmlEntities count];
		for (i = 0; i < count; i++)
		{
			NSString* escaped = htmlEntities[i];
			NSRange range = [result rangeOfString:escaped];
			if (range.location != NSNotFound)
			{
				[result replaceOccurrencesOfString: escaped 
										withString: [NSString stringWithFormat: @"%C", (unichar)(160 + i)]
										   options: NSLiteralSearch 
											 range: NSMakeRange(0, [result length])];
			}
		}
		// Finally the XML forbidden chars
		[result replaceOccurrencesOfString:@"&amp;" withString:@"&" options:NSLiteralSearch range:NSMakeRange(0, [result length])];
		[result replaceOccurrencesOfString:@"&lt;" withString:@"<" options:NSLiteralSearch range:NSMakeRange(0, [result length])];
		[result replaceOccurrencesOfString:@"&gt;" withString:@">" options:NSLiteralSearch range:NSMakeRange(0, [result length])];
		[result replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:NSLiteralSearch range:NSMakeRange(0, [result length])];
		[result replaceOccurrencesOfString:@"&apos;" withString:@"'" options:NSLiteralSearch range:NSMakeRange(0, [result length])];
	}
	return result;
}

-(NSString *)stringByUnescapingExtendedCharacters
{
    NSMutableString * processedString = [[NSMutableString alloc] initWithString:self];
    NSUInteger entityStart;
    NSUInteger entityEnd;
    
    entityStart = [processedString indexOfCharacterInString:'&' afterIndex:0];
    while (entityStart != NSNotFound)
    {
        entityEnd = [processedString indexOfCharacterInString:';' afterIndex:entityStart + 1];
        if (entityEnd != NSNotFound)
        {
            NSRange entityRange = NSMakeRange(entityStart, (entityEnd - entityStart) + 1);
            NSRange innerEntityRange = NSMakeRange(entityRange.location + 1, entityRange.length - 2);
            NSString * entityString = [processedString substringWithRange:innerEntityRange];
            [processedString replaceCharactersInRange:entityRange withString:[NSString privateMapEntityToString:entityString]];
        }
        entityStart = [processedString indexOfCharacterInString:'&' afterIndex:entityStart + 1];
    }
    
    return [processedString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];;
}


- (NSUInteger) indexOfCharacterInString:(char)ch afterIndex:(NSUInteger)startIndex
{
	NSUInteger length = [self length];
	NSUInteger index = 0;
	
	if (startIndex < length - 1)
		for (index = startIndex; index < length; ++index)
		{
			if ([self characterAtIndex:index] == ch)
				return index;
		}
	return NSNotFound;
}

- (NSString*) pathByRemovingQueryString
{
	NSRange range = [self rangeOfString:@"?"];
	if (range.location == NSNotFound) return self;
	return [self substringToIndex:range.location];
}

@end

@implementation NSString(PStringPrivateExtensions)

+(NSString *)privateMapEntityToString:(NSString *)entityString
{
    static NSMutableDictionary * sPStringExtensionsEntityMap = nil;
    
	if (sPStringExtensionsEntityMap == nil)
	{
		sPStringExtensionsEntityMap = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        @"<",	@"lt",
                                        @">",	@"gt",
                                        @"\"",	@"quot",
                                        @"&",	@"amp",
                                        @"'",	@"rsquo",
                                        @"'",	@"lsquo",
                                        @"'",	@"apos",
                                        @"...", @"hellip",
                                        @" ",	@"nbsp",
                                        nil,	nil];
		
		// Add entities that map to non-ASCII characters
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xA1)] forKey:@"iexcl"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xA2)] forKey:@"cent"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xA3)] forKey:@"pound"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xA4)] forKey:@"curren"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xA5)] forKey:@"yen"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xA6)] forKey:@"brvbar"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xA7)] forKey:@"sect"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xA8)] forKey:@"uml"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xA9)] forKey:@"copy"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xAA)] forKey:@"ordf"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xAB)] forKey:@"laquo"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xAC)] forKey:@"not"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xAE)] forKey:@"reg"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xAF)] forKey:@"macr"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xB0)] forKey:@"deg"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xB1)] forKey:@"plusmn"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xB2)] forKey:@"sup2"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xB3)] forKey:@"sup3"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xB4)] forKey:@"acute"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xB5)] forKey:@"micro"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xB6)] forKey:@"para"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xB7)] forKey:@"middot"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xB8)] forKey:@"cedil"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xB9)] forKey:@"sup1"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xBA)] forKey:@"ordm"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xBB)] forKey:@"raquo"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xBC)] forKey:@"frac14"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xBD)] forKey:@"frac12"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xBE)] forKey:@"frac34"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xBF)] forKey:@"iquest"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xC0)] forKey:@"Agrave"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xC1)] forKey:@"Aacute"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xC3)] forKey:@"Atilde"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xC4)] forKey:@"Auml"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xC5)] forKey:@"Aring"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xC6)] forKey:@"AElig"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xC7)] forKey:@"Ccedil"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xC8)] forKey:@"Egrave"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xC9)] forKey:@"Eacute"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xCA)] forKey:@"Ecirc"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xCB)] forKey:@"Euml"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xCC)] forKey:@"Igrave"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xCD)] forKey:@"Iacute"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xCE)] forKey:@"Icirc"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xCF)] forKey:@"Iuml"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xD0)] forKey:@"ETH"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xD1)] forKey:@"Ntilde"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xD2)] forKey:@"Ograve"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xD3)] forKey:@"Oacute"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xD4)] forKey:@"Ocirc"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xD5)] forKey:@"Otilde"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xD6)] forKey:@"Ouml"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xD7)] forKey:@"times"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xD8)] forKey:@"Oslash"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xD9)] forKey:@"Ugrave"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xDA)] forKey:@"Uacute"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xDB)] forKey:@"Ucirc"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xDC)] forKey:@"Uuml"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xDD)] forKey:@"Yacute"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xDE)] forKey:@"THORN"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xDF)] forKey:@"szlig"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xE0)] forKey:@"agrave"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xE1)] forKey:@"aacute"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xE2)] forKey:@"acirc"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xE3)] forKey:@"atilde"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xE4)] forKey:@"auml"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xE5)] forKey:@"aring"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xE6)] forKey:@"aelig"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xE7)] forKey:@"ccedil"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xE8)] forKey:@"egrave"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xE9)] forKey:@"eacute"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xEA)] forKey:@"ecirc"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xEB)] forKey:@"euml"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xEC)] forKey:@"igrave"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xED)] forKey:@"iacute"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xEE)] forKey:@"icirc"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xEF)] forKey:@"iuml"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xF0)] forKey:@"eth"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xF1)] forKey:@"ntilde"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xF2)] forKey:@"ograve"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xF3)] forKey:@"oacute"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xF4)] forKey:@"ocirc"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xF5)] forKey:@"otilde"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xF6)] forKey:@"ouml"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xF7)] forKey:@"divide"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xF8)] forKey:@"oslash"];
        [sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xF9)] forKey:@"ugrave"];
        [sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xFA)] forKey:@"uacute"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xFB)] forKey:@"ucirc"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xFC)] forKey:@"uuml"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xFD)] forKey:@"yacute"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xFE)] forKey:@"thorn"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xC3C)] forKey:@"sigma"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0xCA3)] forKey:@"Sigma"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0x2022)] forKey:@"bull"];
		[sPStringExtensionsEntityMap setValue:[NSString stringWithFormat:@"%C", (unichar)(0x20AC)] forKey:@"euro"];
	}
	
	// Parse off numeric codes of the format #xxx
	if ([entityString length] > 1 && [entityString characterAtIndex:0] == '#')
	{
		NSUInteger intValue;
		if ([entityString characterAtIndex:1] == 'x')
			intValue = [[entityString substringFromIndex:2] hexValue];
		else
			intValue = [[entityString substringFromIndex:1] intValue];
		return [NSString stringWithFormat:@"%C", (unichar)MAX(intValue, ' ')];
	}
	
	NSString * mappedString = sPStringExtensionsEntityMap[entityString];
	return mappedString ? mappedString : [NSString stringWithFormat:@"&%@;", entityString];
}

@end
