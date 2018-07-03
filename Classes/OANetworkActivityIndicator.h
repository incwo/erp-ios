@interface OANetworkActivityIndicator : NSObject
{
  NSInteger count;
}

+ (void) push;
+ (void) pop;
+ (BOOL) isActive;

- (void) push;
- (void) pop;
- (BOOL) isActive;

@end
