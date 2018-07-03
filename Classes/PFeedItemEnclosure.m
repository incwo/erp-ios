//
//  IGFeedItem
//
//

#import "PFeed.h"
#import "PFeedItemEnclosure.h"
#import "OAXMLDecoder.h"
#import "PDictionaryExtensions.h"
#import "PStringExtensions.h"

NSString* const LIFeedItemEnclosureStatusNotLoaded = @"LIFeedItemEnclosureStatusNotLoaded";
NSString* const LIFeedItemEnclosureStatusLoading   = @"LIFeedItemEnclosureStatusLoading";
NSString* const LIFeedItemEnclosureStatusLoaded    = @"LIFeedItemEnclosureStatusLoaded";

@interface NSString (LI_URL)
- (NSURL*) LI_URL;
- (NSURL*) LI_fileURL;
@end

@implementation NSString (LI_URL)
- (NSURL*) LI_URL
{
	return [NSURL URLWithString:self];
}
- (NSURL*) LI_fileURL
{
	return [NSURL fileURLWithPath:self];
}
@end


@interface PFeedItemEnclosure ()

@end

@implementation PFeedItemEnclosure

+ (PFeedItemEnclosure*) enclosure
{
	return [self new];
}


- (BOOL) isLoaded
{
	return [self.status isEqualToString:LIFeedItemEnclosureStatusLoaded];
}

- (BOOL) isLoading
{
	return [self.status isEqualToString:LIFeedItemEnclosureStatusLoading];
}

- (BOOL) isNotLoaded
{
	return !self.status || [self.status isEqualToString:LIFeedItemEnclosureStatusNotLoaded];
}

- (NSURL*) localOrRemoteURL
{
	if (self.localURL && [self isLoaded])
	{
		return self.localURL;
	}
	return self.URL;
}


#pragma mark Equal



- (BOOL)isEqual:(PFeedItemEnclosure*)object
{
	return (self == object) || ([object isKindOfClass:[self class]] && [self.URL isEqual:object.URL]);
}

- (NSUInteger)hash
{
	return [self.URL hash];
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"<%@:%p %@ %@>", [self class], self, self.URL, self.status];
}




#pragma mark NSCoding



- (id)initWithCoder:(NSCoder*)aDecoder
{
	if ((self = [super init]))
	{
		self.type     = [aDecoder decodeObjectForKey:@"type"];
		self.URL      = [aDecoder decodeObjectForKey:@"URL"];
		self.status   = [aDecoder decodeObjectForKey:@"status"];
		
		if ([self.status isEqualToString:LIFeedItemEnclosureStatusLoaded]) self.status = LIFeedItemEnclosureStatusLoaded;
		else if ([self.status isEqualToString:LIFeedItemEnclosureStatusLoading]) self.status = LIFeedItemEnclosureStatusLoading;
		else self.status = LIFeedItemEnclosureStatusNotLoaded;
		
		self.localURL = [aDecoder decodeObjectForKey:@"localURL"];
		
		self.length             = [aDecoder decodeIntegerForKey:@"length"];
		self.widthNumber        = [aDecoder decodeObjectForKey:@"widthNumber"];
		self.heightNumber       = [aDecoder decodeObjectForKey:@"heightNumber"];
		self.duration           = [aDecoder decodeDoubleForKey:@"duration"];
        self.legend             = [aDecoder decodeObjectForKey:@"legend"];
		self.downloadProgress   = [aDecoder decodeFloatForKey:@"downloadProgress"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder*)aCoder
{
	[aCoder encodeObject:self.type forKey:@"type"];
	[aCoder encodeObject:self.URL forKey:@"URL"];
	[aCoder encodeObject:self.status forKey:@"status"];
	[aCoder encodeObject:self.localURL forKey:@"localURL"];
	
	[aCoder encodeObject:self.widthNumber forKey:@"widthNumber"];
	[aCoder encodeObject:self.heightNumber forKey:@"heightNumber"];
	[aCoder encodeInteger:self.length forKey:@"length"];
	[aCoder encodeDouble:self.duration forKey:@"duration"];
    [aCoder encodeObject:self.legend forKey:@"legend"];
	[aCoder encodeFloat:self.downloadProgress forKey:@"downloadProgress"];
}






- (PFeedItemEnclosure*) validEnclosure
{
	// return nil if invalid, or fix possible issues and return self
	if (!self.URL) return nil;
	[self updateStatus];
	return self;
}

- (void) decodeWithDecoder:(OAXMLDecoder*)decoder forFeed:(PFeed*)aFeed
{
	self.type = [decoder attributeForName:@"type"];
	self.URL = [NSURL URLWithString:[[decoder attributeForName:@"url"] stringByAddingPercentEscapesToSpaces]];
	
	NSString* lengthString = [decoder.currentAttributes firstObjectForKeys:@"fileSize", @"length", nil];
	NSString* widthString = [decoder.currentAttributes firstObjectForKeys:@"cineobs:width", nil];
	NSString* heightString = [decoder.currentAttributes firstObjectForKeys:@"cineobs:height", nil];
	NSString* durationString = [decoder.currentAttributes firstObjectForKeys:@"duration", nil];
    self.legend = [decoder.currentAttributes firstObjectForKeys:@"cineobs:legend", nil];

	if (lengthString)
	{
		NSInteger aLength = [lengthString integerValue];
		if (aLength > 0)
		{
			self.length = aLength;
		}
		else
		{
			self.length = 0;
			// LIWARNING(@"Enclosure for feed %@ is declared with size = %d bytes. Using 0.", aFeed.URL, aLength);
		}
	}
	
	if (widthString)
	{
		NSInteger aWidth = [widthString integerValue];
		if (aWidth > 0)
		{
			self.widthNumber = [NSNumber numberWithInteger:aWidth];
		}
		else
		{
			self.widthNumber = nil;
		}
	}
    if (heightString)
	{
		NSInteger aHeight = [heightString integerValue];
		if (aHeight > 0)
		{
			self.heightNumber = [NSNumber numberWithInteger:aHeight];
		}
		else
		{
			self.heightNumber = nil;
		}
	}
	

	if (durationString)
	{
		NSTimeInterval aDuration = [durationString doubleValue];
		if (aDuration > 0)
		{
			self.duration = aDuration;
		}
		else
		{
			self.duration = 0;
			// LIWARNING(@"Enclosure for feed %@ is declared with duration = %f sec. Using 0.", aFeed.URL, aDuration);
		}
	}
}

- (void) updateStatus
{
	// [DATAMODEL.enclosureManager updateEnclosure:self];
}


@end
