
@interface UIViewController (OANavigationState)
- (void) setNavigationState:(id)state;
- (id) navigationState;
- (UIViewController*) nextViewController;
@end
