//
//  PDictionaryExtensions.m

//
//

#import "PDictionaryExtensions.h"


@implementation NSDictionary(PDictionaryExtensions)

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
