//
//  PFeedItemThumbnail.m
//
//

#import "PFeedItemThumbnail.h"
#import "PFeed.h"
#import "OAXMLDecoder.h"
#import "PStringExtensions.h"

@implementation PFeedItemThumbnail

#pragma mark Equal


- (BOOL)isEqual:(PFeedItemThumbnail*)object
{
	return (self == object) || ([object isKindOfClass:[self class]] && [self.URL isEqual:object.URL]);
}

- (NSUInteger)hash
{
	return [self.URL hash];
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"<%@:%p %@ %ldx%ld>", [self class], self, self.URL, (long)self.width, (long)self.height];
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder*)aDecoder
{
	if ((self = [super init]))
	{
		self.URL      = [aDecoder decodeObjectForKey:@"URL"];
		self.width    = [aDecoder decodeIntegerForKey:@"width"];
		self.height   = [aDecoder decodeIntegerForKey:@"height"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder*)aCoder
{
	[aCoder encodeObject:self.URL forKey:@"URL"];
	[aCoder encodeInteger:self.width forKey:@"width"];
	[aCoder encodeInteger:self.height forKey:@"height"];
}

#pragma mark FeedParsing

- (void) decodeWithDecoder:(OAXMLDecoder*)decoder forFeed:(PFeed*)aFeed
{
	NSString* string = [decoder.currentAttributes objectForKey:@"url"];
	self.URL = [NSURL URLWithString:[string stringByAddingPercentEscapesToSpaces]];
	string = [decoder.currentAttributes objectForKey:@"width"];
	if (string)
	{
		self.width = [string intValue];
	}
	string = [decoder.currentAttributes objectForKey:@"height"];
	if (string)
	{
		self.height = [string intValue];
	}
}

- (PFeedItemThumbnail*) validThumbnail
{
	// return nil if invalid, or fix possible issues and return self
	if (self.URL == nil) return nil;
	return self;
}


@end
