#import "OANetworkActivityIndicator.h"

OANetworkActivityIndicator* globalNetworkActivityIndicator;
@implementation OANetworkActivityIndicator

- (id) init
{
    if (self = [super init])
    {
        count = 0;
    }
    return self;
}

+ (OANetworkActivityIndicator*)instance
{
    @synchronized(self)
    {
        if (globalNetworkActivityIndicator == nil)
            globalNetworkActivityIndicator = [[OANetworkActivityIndicator alloc] init];
    }
	return globalNetworkActivityIndicator;
}

- (void) updateValueOnUnknownThread:(BOOL)v
{
    [self performSelectorOnMainThread:
     @selector(updateValueOnMainThread:) withObject:
     [NSNumber numberWithBool:v] waitUntilDone:NO];
}

- (void) updateValueOnMainThread:(NSNumber*)v
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = [v boolValue];
}

- (void) push
{
    @synchronized(self)
    {
        count++;
        if (count == 1) [self updateValueOnUnknownThread:YES];
    }
}

- (void) pop
{
    @synchronized(self)
	{
        count--;
        if (count == 0) [self updateValueOnUnknownThread:NO];
    }
}

- (BOOL) isActive
{
    return count > 0;
}

+ (void) push
{
    [[self instance] push];
}

+ (void) pop
{
    [[self instance] pop];
}

+ (BOOL) isActive
{
    return [[self instance] isActive];
}
@end
