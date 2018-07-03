//
//  IGFeed
//
//

#import "PFeed.h"
#import "PFeedItem.h"
#import "OAXMLDecoder.h"
#import "PDictionaryExtensions.h"
#import "PStringExtensions.h"

@interface PFeed()

@property (nonatomic, retain) NSMutableDictionary *xmlStash;
@property (nonatomic) NSUInteger unreadCount;

@end

@implementation PFeed

@synthesize description = _description; // Must be synthesized explicitely because the method is inherited from NSObject, where it is readonly.

- (id) copyWithZone:(NSZone *)aZone
{
	PFeed* newFeed = [[PFeed allocWithZone:aZone] init];
	newFeed.items       = nil;
	newFeed.uid         = self.uid;
	newFeed.URL         = self.URL;
	newFeed.title       = self.title;
	newFeed.description = self.description;
	newFeed.copyright   = self.copyright;
	return newFeed;
}

- (void) updateUnreadCount
{
	NSUInteger count = 0;
	for (PFeedItem* item in self.items)
	{
		count += (NSUInteger)(!item.isRead);
	}
	self.unreadCount = count;
}

- (void)setItems:(NSArray *)items {
    if (_items != items) {
        _items = items;
        [self updateUnreadCount];
    }
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super init]))
	{
		self.uid         = [aDecoder decodeObjectForKey:@"uid"];
		self.URL         = [aDecoder decodeObjectForKey:@"URL"];
		self.title       = [aDecoder decodeObjectForKey:@"title"];
		self.description = [aDecoder decodeObjectForKey:@"description"];
		self.copyright   = [aDecoder decodeObjectForKey:@"copyright"];
		self.items       = [aDecoder decodeObjectForKey:@"items"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.uid forKey:@"uid"];
	[aCoder encodeObject:self.URL forKey:@"URL"];
	[aCoder encodeObject:self.title forKey:@"title"];
	[aCoder encodeObject:self.description forKey:@"description"];
	[aCoder encodeObject:self.copyright forKey:@"copyright"];
	[aCoder encodeObject:self.items forKey:@"items"];
}


#pragma mark Equal

- (BOOL)isEqual:(id)object
{
	return (self == object) || 
	       ([object isKindOfClass:[self class]] && [self.uid isEqualToString:((PFeed*)object).uid]);
}

- (NSUInteger)hash
{
	return [self.uid hash];
}

#pragma mark OAXMLDecoder

- (void) decodeFeedWithDecoder:(OAXMLDecoder*)decoder
{
	[decoder endElement:@"UID" withBlock:^{
		self.uid = decoder.currentString;
	}];
	[decoder endElement:@"NAME" withBlock:^{
		self.title = decoder.currentString;
	}];
	[decoder endElement:@"DESCRIPTION" withBlock:^{
		self.description = decoder.currentString;
	}];
	[decoder endElement:@"URL_XML" withBlock:^{
		self.URL = [NSURL URLWithString:[decoder.currentStringStripped stringByAddingPercentEscapesToSpaces]];
		//NSLog(@"LIFeed: parsed XML URL: %@", self.URL);
	}];
}


- (void) decodeFeedRSSWithDecoder:(OAXMLDecoder*)decoder
{
	NSDate *minimumFeedItemAllowedDate = nil;//[[NSDate date] dateByAddingTimeInterval:-60*60*24*30];	// 30 days ago
	
	[decoder.xmlParser setShouldResolveExternalEntities:NO]; // like in NPFeedParser
	[decoder.xmlParser setShouldProcessNamespaces:YES]; // like in NPFeedParser
	
	// decoder.traceParsing = YES;
	
	NSMutableArray* newItems = [NSMutableArray array];
	
	self.xmlStash = [NSMutableDictionary dictionary];
	
	[decoder parseElements:[NSSet setWithObjects:@"rss", @"atom", @"rdf:rdf", @"rss:channel", @"feed", nil] startBlock:^{
		[decoder startOptionalElements:[NSSet setWithObjects:@"channel", @"feed", nil] withBlock:^{
			__block PFeedItem* feedItem = nil;
			[decoder parseElements:[NSSet setWithObjects:@"item", @"entry", nil] startBlock:^{
				
				feedItem = [PFeedItem feedItem];
				[feedItem decodeWithRSSDecoder:decoder forFeed:self];
			} endBlock:^{
				feedItem = [feedItem validFeedItemAfterParsingForMinimumAllowedDate:(NSDate *)minimumFeedItemAllowedDate];
				if (feedItem)
				{
					[newItems addObject:feedItem];
				}
				feedItem = nil;
			}];
			
			[decoder parseElement:@"link" startBlock:^{
				NSString* rel = [decoder attributeForName:@"rel"];
				NSString* href = [decoder attributeForName:@"href"];
				if (href && [href length] > 0 && (rel == nil || [rel isEqualToString:@"alternate"]))
				{
					self.primarySiteURL = [NSURL URLWithString:[href stringByAddingPercentEscapesToSpaces]];
				}
			} endBlock:nil];
			
			self.displayPreviewImage = NO;
			
			[decoder parseElements:[NSSet setWithObjects:@"image", @"itunes:image", nil] startBlock:^{
				NSString* href = [decoder attributeForName:@"href"];
				if (href && [href length] > 0)
				{
					self.imageURL = [NSURL URLWithString:[href stringByAddingPercentEscapesToSpaces]];
					self.displayPreviewImage = self.displayPreviewImage || [decoder.currentQualifiedName isEqualToString:@"itunes:image"];
				}
			} endBlock:nil];
			
			
			// Image from Le Monde-style RSS
			
			[decoder startElement:@"image" withBlock:^{
				[decoder endElement:@"url" withBlock:^{
					NSString* imageURLString = [decoder currentStringStripped];
					if (imageURLString && [imageURLString length] > 0)
					{
						self.imageURL = [NSURL URLWithString:[imageURLString stringByAddingPercentEscapesToSpaces]];
					}
				}];
			}];
			
			// The code below is ported from NSFeedParser, fillFeed:withAcc: method
			
			[decoder endElement:@"title" withBlock:^{
				// self.title = [decoder.currentStringStripped stringByResolvingHTMLEntities];
			}];
			
			[decoder endElements:[NSSet setWithObjects:
									   @"content:encoded",
									   @"description",
									   @"itunes:summary",
									   @"subtitle",
									   @"itunes:subtitle",
									   nil] withBlock:^{
				[self.xmlStash setObject:[decoder.currentStringStripped stringByResolvingHTMLEntities] forKey:decoder.currentQualifiedName];
			}];
			
			[decoder endElements:[NSSet setWithObjects:@"copyright", @"rights", nil] withBlock:^{
				if (!self.copyright)
				{
					self.copyright = [decoder.currentStringStripped stringByResolvingHTMLEntities];
				}
			}];
			
		}];
	} endBlock:^{
		self.description = [self.xmlStash firstObjectForKeys:
							@"content:encoded",
							@"description",
							@"itunes:summary",
							@"subtitle",
							@"itunes:subtitle",
							nil];
				
		self.items = [newItems sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"pubDate" ascending:NO]]];
		self.xmlStash = nil;
	}];
}

@end













