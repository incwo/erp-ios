#import "OANavigationState.h"

@implementation UIViewController (OANavigationState)

- (void) setNavigationState:(id)state
{
    // override in a subclass
}

- (id) navigationState
{
    // override in a subclass
    return [NSMutableDictionary dictionary];
}

- (UIViewController*) nextViewController
{
    NSArray* ctrls = self.navigationController.viewControllers;
    if (ctrls)
    {
        NSUInteger index = [ctrls indexOfObject:self];
        if (index == NSNotFound) return nil;
        if (index >= ([ctrls count] - 1)) return nil;
        return [ctrls objectAtIndex:index + 1];
    }
    return nil;
}

@end

@implementation UINavigationController (OANavigationState)

- (UIViewController*) oa_rootViewController
{
    NSArray* ctrls = [self viewControllers];
    if (ctrls && [ctrls count] > 0)
    {
        return [ctrls objectAtIndex:0];
    }
    return nil;
}

- (void) setNavigationState:(id)state
{
    [[self oa_rootViewController] setNavigationState:state];
}

- (id) navigationState
{
    return [[self oa_rootViewController] navigationState];
}

@end
