//
//  IGFeedItem
//
//

#import "PFeed.h"
#import "PFeedItem.h"
#import "PFeedItemEnclosure.h"
#import "OAXMLDecoder.h"
#import "PDictionaryExtensions.h"
#import "PStringExtensions.h"
#import "PDateExtension.h"
#import "PFeedItemEnclosure.h"
#import "PFeedItemThumbnail.h"



@interface PFeedItem ()

@property(nonatomic) NSMutableDictionary *xmlStash;

- (PFeedItemEnclosure *) nativeImageEnclosure;
- (PFeedItemEnclosure *) nativeVideoEnclosure;
- (PFeedItemEnclosure *) nativeAudioEnclosure;
- (void) enumerateEnclosuresWithTypeMatching:(NSString *)mimeTypeSubstring usingBlock:(void(^)(PFeedItemEnclosure *enclosure, BOOL *stop))block;

@end

@interface NSString(PFeedItem)

- (BOOL) PFeedItem_hasImagePathExtension;
- (NSString*) stringByStrippingHTML;

@end

@implementation PFeedItem

+ (PFeedItem*) feedItem
{
	return [self new];
}

- (void) setRead:(BOOL)read
{
	if (read == _read) return;
	_read = read;
	[self.feed updateUnreadCount];
}

- (BOOL) hasAudio
{
	return !!self.nativeAudioURL;
}

- (BOOL) shouldSurviveAutoRemoval
{
	if ([self isHidden]) return NO;
	if (![self downloadableEnclosure]) return NO;
	
	return ([[self downloadableEnclosure] isLoaded] || [[self downloadableEnclosure] isLoading]);
}




#pragma mark Sync



- (void) replaceWithObject:(PFeedItem*)newFeedItem
{
	if (self.imageURL && (!newFeedItem.imageURL || ![newFeedItem.imageURL isEqual:self.imageURL]))
	{
		// FIXME: in fact, instead of clearing a cache just like that, it's better to remember the imageURL 
		// so that datamodel disposes it as it likes when it wants.
		// [DATAMODEL clearCacheForURL:self.imageURL];
	}
	
	if (self.hidden)
	{
		// LINOTE(@"Updating data for %@", self);
	}
	
	self.guid = newFeedItem.guid;
	self.title = newFeedItem.title;
	self.htmlDescription = newFeedItem.htmlDescription;
	self.textDescription = newFeedItem.textDescription;
	self.podcastHTMLDescription = newFeedItem.podcastHTMLDescription;
	self.pubDate = newFeedItem.pubDate;
	self.linkURL = newFeedItem.linkURL;
	self.imageURL = newFeedItem.imageURL;

	// Note: read and hidden attributes should not be updated.
	
	self.enclosures = newFeedItem.enclosures;
	self.thumbnails = newFeedItem.thumbnails;
}






#pragma mark Equal



- (BOOL) isEqual:(id)object
{
	return (self == object) || ([object isKindOfClass:[self class]] && [self.guid isEqualToString:((PFeedItem*)object).guid]);
}

- (NSUInteger) hash
{
	return [self.guid hash];
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"<LIFeedItem: %p guid=%@ title=%@>", self, self.guid, self.title];
}

#pragma mark AudioPlayerItem


- (NSURL*) playerItemStreamURL
{
	return self.nativeAudioURL;
}

- (BOOL) playerItemWantsMoviePlayerController
{
	return YES;
}

- (NSString*) playerItemTitle
{
	return self.title;
}

- (NSString*) playerItemSubtitle
{
	return self.textDescription;
}

- (NSString*) playerItemLiveTitle
{
	return self.title;
}

- (NSString*) playerItemLiveDescription
{
	return self.textDescription;
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super init]))
	{
		self.guid = [aDecoder decodeObjectForKey:@"guid"];
		self.title = [aDecoder decodeObjectForKey:@"title"];
		self.htmlDescription = [aDecoder decodeObjectForKey:@"htmlDescription"];
		self.textDescription = [aDecoder decodeObjectForKey:@"textDescription"];
		self.htmlFulltext = [aDecoder decodeObjectForKey:@"htmlFulltext"];
		self.textFulltext = [aDecoder decodeObjectForKey:@"textFulltext"];
		self.category = [aDecoder decodeObjectForKey:@"category"];
        self.author = [aDecoder decodeObjectForKey:@"author"];
        self.authorName = [aDecoder decodeObjectForKey:@"authorName"];
        self.sourceName = [aDecoder decodeObjectForKey:@"sourceName"];
        self.categoryName = [aDecoder decodeObjectForKey:@"categoryName"];
		self.legend = [aDecoder decodeObjectForKey:@"legend"];
        self.pubDate = [aDecoder decodeObjectForKey:@"pubDate"];
		self.linkURL = [aDecoder decodeObjectForKey:@"linkURL"];
		self.imageURL = [aDecoder decodeObjectForKey:@"imageURL"];
		self.read = [aDecoder decodeBoolForKey:@"read"];
		self.hidden = [aDecoder decodeBoolForKey:@"hidden"];
		self.enclosures = [aDecoder decodeObjectForKey:@"enclosures"];
		self.thumbnails = [aDecoder decodeObjectForKey:@"thumbnails"];
		self.feed = [aDecoder decodeObjectForKey:@"feed"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.guid forKey:@"guid"];
	[aCoder encodeObject:self.title forKey:@"title"];
	[aCoder encodeObject:self.htmlDescription forKey:@"htmlDescription"];
	[aCoder encodeObject:self.textDescription forKey:@"textDescription"];
	[aCoder encodeObject:self.htmlFulltext forKey:@"htmlFulltext"];
	[aCoder encodeObject:self.textFulltext forKey:@"textFulltext"];
    [aCoder encodeObject:self.category forKey:@"category"];
    [aCoder encodeObject:self.author forKey:@"author"];
    [aCoder encodeObject:self.authorName forKey:@"authorName"];
    [aCoder encodeObject:self.sourceName forKey:@"sourceName"];
    [aCoder encodeObject:self.categoryName forKey:@"categoryName"];
    [aCoder encodeObject:self.legend forKey:@"legend"];
	[aCoder encodeObject:self.pubDate forKey:@"pubDate"];
	[aCoder encodeObject:self.linkURL forKey:@"linkURL"];
	[aCoder encodeObject:self.imageURL forKey:@"imageURL"];
	[aCoder encodeBool:self.isRead forKey:@"read"];
	[aCoder encodeBool:self.isHidden forKey:@"hidden"];
	[aCoder encodeObject:self.enclosures forKey:@"enclosures"];
	[aCoder encodeObject:self.thumbnails forKey:@"thumbnails"];
	
	[aCoder encodeConditionalObject:self.feed forKey:@"feed"];
}

#pragma mark XML parsing

- (void) decodeWithRSSDecoder:(OAXMLDecoder*)decoder forFeed:(PFeed*)aFeed
{
	self.feed = aFeed;
	
	// These two lines assume we have "retain", not "copy" property mode.
	NSMutableArray* enclosuresBuffer = [NSMutableArray array]; 
	self.enclosures = enclosuresBuffer;
	
	self.xmlStash = [NSMutableDictionary dictionary];
	
	__block PFeedItemEnclosure* enclosure = nil;
	
	[decoder startOptionalElement:@"media:group" withBlock:^{
		[decoder parseElements:[NSSet setWithObjects:@"media:content", @"enclosure",nil] startBlock:^{
			
			enclosure = [PFeedItemEnclosure enclosure];
			[enclosure decodeWithDecoder:decoder forFeed:aFeed];
			
		} endBlock:^{
			enclosure = [enclosure validEnclosure];
			if (enclosure)
			{
				[enclosuresBuffer addObject:enclosure];
			}
			enclosure = nil;
		}];
	}];
	
	// These two lines assume we have "retain", not "copy" property mode.
	NSMutableArray* thumbnailsBuffer = [NSMutableArray array]; 
	self.thumbnails = thumbnailsBuffer;
		
	__block PFeedItemThumbnail* thumbnail = nil;
	
	[decoder parseElements:[NSSet setWithObjects:@"media:thumbnail",nil] startBlock:^{
		
		thumbnail = [[PFeedItemThumbnail alloc] init];
		[thumbnail decodeWithDecoder:decoder forFeed:aFeed];
		
	} endBlock:^{
		thumbnail = [thumbnail validThumbnail];
		if (thumbnail)
		{
			[thumbnailsBuffer addObject:thumbnail];
		}
		thumbnail = nil;
	}];
	
	// Support both ways to declare a link:
	// 1. <link href="..." />
	// 2. <link>...</link>
	// Ignore all links with rel="..." (if not "alternate" or not specified)
	[decoder parseElement:@"link" startBlock:^{
		NSString* rel = [decoder attributeForName:@"rel"];
		NSString* href = [decoder attributeForName:@"href"];
		if (href && (!rel || [rel isEqualToString:@"alternate"]))
		{
			self.linkURL = [NSURL URLWithString:[href stringByAddingPercentEscapesToSpaces] relativeToURL:aFeed.primarySiteURL];
		}
	} endBlock:^{
		if (self.linkURL) return;
		NSString* rel = [decoder attributeForName:@"rel"];
		NSString* href = decoder.currentStringStripped;
		if (href && ![href isEqualToString:@""] && (!rel || [rel isEqualToString:@"alternate"]))
		{
			self.linkURL = [NSURL URLWithString:[href stringByAddingPercentEscapesToSpaces] relativeToURL:aFeed.primarySiteURL];
		}
	}];
    
	[decoder endElement:@"author" withBlock:^{
		self.author = [decoder.currentStringStripped stringByResolvingHTMLEntities];
	}];
    
	// test: [decoder attributeForNames:@"fileSize", @"length", nil];
	// The code below is ported from NPFeedParser fillFeedItem:withAcc:
		
	[decoder endElement:@"title" withBlock:^{
		NSString* theTitle = decoder.currentStringStripped;
		theTitle = [theTitle stringByReplacingOccurrencesOfString:@"" withString:@"’"]; // WORKAROUND for server encoding problems
		theTitle = [theTitle stringByResolvingHTMLEntities];
		
		self.title = theTitle;
	}];
	
	[decoder endElement:@"category" withBlock:^{
		self.category = [decoder.currentStringStripped stringByResolvingHTMLEntities];
	}];
	
	// get description from content.div.p path
	[decoder startElement:@"content" withBlock:^{
		[decoder startElement:@"div" withBlock:^{
			[decoder endElement:@"p" withBlock:^{
				
				// TODO: need to guarantee that all inner tags are collected in a string buffer.
				
				[self.xmlStash setObject:[decoder.currentStringStripped stringByResolvingHTMLEntities] forKey:@"content.div.p"];
			}];
		}];
	}];
	
	[decoder endElements:[NSSet setWithObjects:
							   @"content:encoded",
							   @"description",
							   @"itunes:subtitle",
							   @"content",
							   @"summary",
							   @"tagline",
							   nil] withBlock:^{
		
		// TODO: need to guarantee that all inner tags are collected in a string buffer.
		// TODO: provide new api for OAXMLDecoder
		
		[self.xmlStash setObject:[decoder.currentStringStripped stringByResolvingHTMLEntities] forKey:decoder.currentQualifiedName];
	}];
	
	[decoder endElement:@"texte" withBlock:^ {
		[self.xmlStash setObject:[decoder.currentStringStripped stringByResolvingHTMLEntities] forKey:decoder.currentQualifiedName];
	}];
	
	[decoder endElements:[NSSet setWithObjects:@"guid", @"id", nil] withBlock:^{
		[self.xmlStash setObject:[decoder.currentStringStripped stringByResolvingHTMLEntities] forKey:decoder.currentQualifiedName];
	}];
	
	[decoder endElements:[NSSet setWithObjects:@"pubdate", @"pubDate", @"updated", @"dc:date", @"modified", nil] withBlock:^{
		[self.xmlStash setObject:[decoder.currentStringStripped stringByResolvingHTMLEntities] forKey:decoder.currentQualifiedName];
	}];
        
	// media:group.media:content.media:url
	[decoder startOptionalElement:@"media:group" withBlock:^{
		[decoder startElement:@"media:content" withBlock:^{
			[decoder startElement:@"media:url" withBlock:^{
				NSString* mediaURLString = [decoder.currentStringStripped stringByResolvingHTMLEntities];
				[self.xmlStash setObject:mediaURLString forKey:@"media:group.media:content.media:url"];
			}];
		}];
	}];
	
    // news feed items
    
    [decoder endElement:@"cineobs:authorName" withBlock:^() {
        self.authorName = decoder.currentStringStripped;
    }];
	
    [decoder endElement:@"cineobs:sourceName" withBlock:^() {
        self.sourceName = decoder.currentStringStripped;
    }];
	
    [decoder endElement:@"cineobs:categoryName" withBlock:^() {
        self.categoryName = decoder.currentStringStripped;
    }];
}




// minimumAllowedDate can be nil (ignored)
- (PFeedItem*) validFeedItemAfterParsingForMinimumAllowedDate:(NSDate *)minimumAllowedDate
{
	if (!self.title || [self.title length] < 1)
	{
		// LIWARNING(@"LIFeedItem does not have title, returning nil.");
		return nil;
	}
	
	if (!self.guid) {
        self.guid = [self.xmlStash firstObjectForKeys:
                     @"guid",
                     @"id",
                     nil];
    }
	
	if (!self.guid)
	{
		self.guid = [[[self.enclosures lastObject] URL] absoluteString];
	}
	if (!self.guid)
	{
		self.guid = [self.linkURL absoluteString];
	}
	if (!self.guid || [self.guid length] < 1)
	{
		// LIWARNING(@"LIFeedItem does not have GUID, returning nil.");
		return nil;
	}
	
	
    if (!self.pubDate) {
        NSString* pubDateString = [self.xmlStash firstObjectForKeys:@"pubdate", @"pubDate", @"updated", @"dc:date", @"modified", nil];
        self.pubDate = [NSDate dateWithHTTPDate:pubDateString];
    }
	
	if (minimumAllowedDate) {
		if (self.pubDate == nil) {
			// LIWARNING(@"LIFeedItem does not have publication date, returning nil.");
			return nil;
		}
		
		if ([self.pubDate timeIntervalSinceDate:minimumAllowedDate] < 0) {
			// LIWARNING(@"LIFeedItem has too old publication date %@, returning nil.", self.pubDate);
			return nil;
		}
	}
	
	
    if (!self.htmlDescription) {
        self.htmlDescription = [self.xmlStash firstObjectForKeys:
                                @"content:encoded",
                                @"description",
                                @"itunes:summary",
                                @"itunes:subtitle",
                                @"content.div.p",
                                @"content",
                                @"summary",
                                @"tagline",
                                nil];
    }
	
    if (!self.podcastHTMLDescription) {
        self.podcastHTMLDescription = [self.xmlStash firstObjectForKeys:
                                       @"itunes:summary",
                                       @"description",
                                       @"content:encoded",
                                       @"content.div.p",
                                       @"content",
                                       @"summary",
                                       @"tagline",
                                       nil];
    }
	
    if (!self.htmlFulltext) {
        self.htmlFulltext = [self.xmlStash objectForKey:@"texte"];
    }
	
    if (!self.imageURL) {
        // Attempt to extract image :
        
        NSString* imageURLString = nil;
        NSString* candidate = nil;
        
        // 1: Try to get image from some enclosure
        if (imageURLString == nil)
        {
            for (PFeedItemEnclosure* enclosure in self.enclosures)
            {
                candidate = [enclosure.URL absoluteString];
                if (candidate && [[candidate pathByRemovingQueryString] PFeedItem_hasImagePathExtension])
                {
                    imageURLString = candidate;
                    break;
                }
            }
        }
        
        // 2: Try a <media:url> tag
        if (imageURLString == nil)
        {
            candidate = [self.xmlStash objectForKey:@"media:group.media:content.media:url"];
            if (candidate && [[candidate pathByRemovingQueryString] PFeedItem_hasImagePathExtension])
            {
                imageURLString = candidate;
            }
        }
        
        // 3: Try to extract images from the description
        if (!imageURLString && self.htmlDescription)
        {
            NSString* html = self.htmlDescription;
            NSRange range = [html rangeOfString: @"<img src='"];
            
            if (range.location != NSNotFound)
            {
                html = [html substringFromIndex: range.location + range.length];
                range = [html rangeOfString: @"'"];
                candidate = [html substringToIndex: range.location];
                if (candidate && [[candidate pathByRemovingQueryString] PFeedItem_hasImagePathExtension])
                {
                    imageURLString = candidate;
                }
            }
            if (!imageURLString)
            {
                html = self.htmlDescription;
                range = [html rangeOfString: @"\" src=\""];
                if (range.location == NSNotFound)
                {
                    range = [html rangeOfString: @"<img src=\""];
                }
                if (range.location != NSNotFound)
                {
                    html = [html substringFromIndex: range.location + range.length];
                    range = [html rangeOfString: @"\""];
                    candidate = [html substringToIndex: range.location];
                    if (candidate && [[candidate pathByRemovingQueryString] PFeedItem_hasImagePathExtension])
                    {
                        imageURLString = candidate;
                    }
                }
            }
            if (!imageURLString)
            {
                html = self.htmlDescription;
                NSRange range = [html rangeOfString: @"<img src=\""];
                
                if (range.location != NSNotFound)
                {
                    html = [html substringFromIndex: range.location + range.length];
                    range = [html rangeOfString: @"\""];
                    candidate = [html substringToIndex: range.location];
                    if (candidate && [[candidate pathByRemovingQueryString] PFeedItem_hasImagePathExtension])
                    {
                        imageURLString = candidate;
                    }
                }
            }
        }
        
        if (imageURLString)
        {
            self.imageURL = [NSURL URLWithString:[imageURLString stringByAddingPercentEscapesToSpaces]];
        }
    }
	
	
	self.xmlStash = nil;
	
	return self;
}

- (NSTimeInterval) duration
{
	NSTimeInterval maxDuration = 0;
	for (PFeedItemEnclosure* enclosure in self.enclosures)
	{
		if (enclosure.duration > maxDuration)
		{
			maxDuration = enclosure.duration;
		}
	}
	return maxDuration;
}

- (void) enumerateEnclosuresWithTypeMatching:(NSString*)mimeTypeSubstring usingBlock:(void(^)(PFeedItemEnclosure *enclosure, BOOL *stop))block
{
    BOOL stop = NO;
	for (PFeedItemEnclosure* enclosure in self.enclosures)
	{
		if ([enclosure.type rangeOfString:mimeTypeSubstring].location != NSNotFound)
		{
            block(enclosure, &stop);
            if (stop) {
                break;
            }
		}
	}
}

- (NSArray*) enclosuresWithTypeMatching:(NSString*)mimeTypeSubstring
{
    NSMutableArray *res = [NSMutableArray array];
    [self enumerateEnclosuresWithTypeMatching:mimeTypeSubstring usingBlock:^(PFeedItemEnclosure *enclosure, BOOL *stop) {
        [res addObject:enclosure];
    }];
    return res;
}

- (PFeedItemEnclosure*) enclosureWithTypeMatching:(NSString*)mimeTypeSubstring
{
	__block PFeedItemEnclosure* res = nil;
    [self enumerateEnclosuresWithTypeMatching:mimeTypeSubstring usingBlock:^(PFeedItemEnclosure *enclosure, BOOL *stop) {
        res = enclosure;
        *stop = YES;
    }];
    return res;
}

- (PFeedItemEnclosure*) downloadableEnclosure
{
	// Prefer video, then sound.
	
	PFeedItemEnclosure* enclosure = [self nativeVideoEnclosure];
	if (enclosure) return enclosure;
	
	enclosure = [self nativeAudioEnclosure];
	if (enclosure) return enclosure;
	
	return nil;
}

- (PFeedItemEnclosure *)nativeImageEnclosure
{
	PFeedItemEnclosure *enclosure = [self enclosureWithTypeMatching:@"image/"];
	if (enclosure) return enclosure;
	return nil;
}

- (PFeedItemEnclosure*) nativeVideoEnclosure
{
    NSArray *videoEnclosures = [[self enclosuresWithTypeMatching:@"video/x-m4v"] arrayByAddingObjectsFromArray:[self enclosuresWithTypeMatching:@"video/mp4"]];
    
    // no video -> easy result
    if (videoEnclosures.count == 0) {
        return nil;
    }
    
    // single video -> easy choice
    if (videoEnclosures.count == 1) {
        return [videoEnclosures lastObject];
    }
    
    // several videos -> use closest to screen resolution
    UIScreen *screen = [UIScreen mainScreen];
    CGSize screenSize = screen.bounds.size;
    CGFloat screenPixelArea = screenSize.width * screenSize.height * screen.scale * screen.scale;
    
    PFeedItemEnclosure *bestEnclosure = nil;
    CGFloat bestEnclosureFit = 0;
    for (PFeedItemEnclosure *enclosure in videoEnclosures) {
        if (bestEnclosure == nil) {
            bestEnclosure = enclosure;
            if (enclosure.widthNumber && enclosure.heightNumber) {
                CGFloat bestEnclosureArea = [enclosure.widthNumber doubleValue] * [enclosure.heightNumber doubleValue];
                bestEnclosureFit = fabs((bestEnclosureArea / screenPixelArea) - 1.0);
            }
        } else if (enclosure.widthNumber && enclosure.heightNumber) {
            CGFloat enclosureArea = [enclosure.widthNumber doubleValue] * [enclosure.heightNumber doubleValue];
            CGFloat enclosureFit = fabs((enclosureArea / screenPixelArea) - 1.0);
            if (enclosureFit < bestEnclosureFit) {
                bestEnclosure = enclosure;
                bestEnclosureFit = enclosureFit;
            }
        }
    }
    return bestEnclosure;
}

- (PFeedItemEnclosure*) nativeAudioEnclosure
{
	PFeedItemEnclosure *enclosure = [self enclosureWithTypeMatching:@"audio/"];
	if (enclosure) return enclosure;
	return nil;
}

					 

@end


@implementation PFeedItem(Formatting)

- (NSURL*) nativeVideoURL
{
//	// test native URL
//	return [NSURL URLWithString:@"http://cdn.kaltura.org/apis/html5lib/kplayer-examples/media/bbb_trailer_iphone.m4v"];

	PFeedItemEnclosure *enclosure = [self nativeVideoEnclosure];
	if (enclosure) {
		return enclosure.localOrRemoteURL;
	}
	return nil;
}

- (NSURL*) nativeImageURL
{
	PFeedItemEnclosure *enclosure = [self nativeImageEnclosure];
	if (enclosure) {
		return enclosure.localOrRemoteURL;
	}
	return nil;
}

- (NSURL *) nativeAudioURL
{
	PFeedItemEnclosure *enclosure = [self nativeAudioEnclosure];
	if (enclosure) {
		return enclosure.localOrRemoteURL;
	}
	return nil;
}

- (NSURL*) videoIframeURL
{
	PFeedItemEnclosure *enclosure = [self enclosureWithTypeMatching:@"text/html"];
	if (enclosure) {
		return enclosure.URL;
	}
	return nil;
}

- (NSNumber*) nativeImageWidthNumber
{
    return self.nativeImageEnclosure.widthNumber;
}

- (NSNumber*) nativeImageHeightNumber
{
    return self.nativeImageEnclosure.heightNumber;
}

- (NSString*) nativeImageLegend
{
    return self.nativeImageEnclosure.legend;
}

- (NSString*) durationFormatted
{
	NSInteger durationInSeconds = (NSInteger)round([self duration]);
	NSInteger mins = durationInSeconds / 60;
	NSInteger secs = durationInSeconds % 60;
	if (durationInSeconds <= 0)
	{
		return @"";
	}
	
	return [NSString stringWithFormat:@"%ld:%02ld", (long)mins, (long)secs];
}

@end

@implementation NSString(PFeedItem)

- (BOOL) PFeedItem_hasImagePathExtension
{
	NSString* ext = [self pathExtension];
	return ext && ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"jpeg"] || [ext isEqualToString:@"png"] || [ext isEqualToString:@"gif"]);   
}

- (NSString*) stringByStrippingHTML
{
	NSMutableString * aString = [NSMutableString stringWithString:self];
	int maxChrs = (int)[self length];
	int cutOff = maxChrs;
	int indexOfChr = 0;
	int tagLength = 0;
	int tagStartIndex = 0;
	BOOL isInQuote = NO;
	BOOL isInTag = NO;
	
	// Rudimentary HTML tag parsing. This could be done by initWithHTML on an attributed string
	// and extracting the raw string but initWithHTML cannot be invoked within an NSURLConnection
	// callback which is where this is probably liable to be used.
	while (indexOfChr < maxChrs)
	{
		unichar ch = [aString characterAtIndex:indexOfChr];
		if (isInTag)
			++tagLength;
		else if (indexOfChr >= cutOff) 
			break;
		
		if (ch == '"')
			isInQuote = !isInQuote;
		else if (ch == '<' && !isInQuote)
		{
			isInTag = YES;
			tagStartIndex = indexOfChr;
			tagLength = 0;
		}
		else if (ch == '>' && isInTag)
		{
			if (++tagLength > 2)
			{
				NSRange tagRange = NSMakeRange(tagStartIndex, tagLength);
				NSString * tag = [[aString substringWithRange:tagRange] lowercaseString];
				int indexOfTagName = 1;
				
				// Extract the tag name
				if ([tag characterAtIndex:indexOfTagName] == '/')
					++indexOfTagName;
				
				int chIndex = indexOfTagName;
				unichar ch = [tag characterAtIndex:chIndex];
				while (chIndex < tagLength && [[NSCharacterSet lowercaseLetterCharacterSet] characterIsMember:ch])
					ch = [tag characterAtIndex:++chIndex];
				
				NSString * tagName = [tag substringWithRange:NSMakeRange(indexOfTagName, chIndex - indexOfTagName)];
				[aString deleteCharactersInRange:tagRange];
				
				// Replace <br> and </p> with newlines
				if ([tagName isEqualToString:@"br"] || [tag isEqualToString:@"<p>"] || [tag isEqualToString:@"<div>"])
					[aString insertString:@"\n" atIndex:tagRange.location];
				
				// Reset scan to the point where the tag started minus one because
				// we bump up indexOfChr at the end of the loop.
				indexOfChr = tagStartIndex - 1;
				maxChrs = (int)[aString length];
				isInTag = NO;
				isInQuote = NO;	// Fix problem with Tribe.net feeds that have bogus quotes in HTML tags
			}
		}
		++indexOfChr;
	}
	
	if (maxChrs > cutOff)
		[aString deleteCharactersInRange:NSMakeRange(cutOff, maxChrs - cutOff)];
	
	return [aString stringByUnescapingExtendedCharacters];
}

@end
