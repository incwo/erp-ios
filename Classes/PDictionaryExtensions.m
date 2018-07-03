//
//  PDictionaryExtensions.m

//
//

#import "PDictionaryExtensions.h"


@implementation NSDictionary(PDictionaryExtensions)

- (NSDictionary*) dictionaryByAddingObject:(id)object forKey:(id)key
{
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:1 + [self count]];
	[dict addEntriesFromDictionary:self];
	dict[key] = object;
	return dict;
}

- (NSDictionary*) dictionaryByRemovingObjectForKey:(id)key
{
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:[self count]];
	[dict addEntriesFromDictionary:self];
	[dict removeObjectForKey:key];
	return dict;
}

- (id) firstObjectForKeys:(id)firstKey, ...
{
	va_list args;
	va_start(args, firstKey);
	id key = firstKey;
	id value = nil;
	while (key) {
		if (!value || value == [NSNull null]) // skip other names if value is found
		{
			value = self[key];
		}
		key = va_arg(args, id);
	}
	va_end(args);
	return value;
}

@end
