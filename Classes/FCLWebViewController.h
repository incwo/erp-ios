@interface FCLWebViewController : UIViewController

- (id) initWithHTML:(NSString*)html baseURL:(NSURL *)baseURL;
- (id) initWithURL:(NSURL*)url;

@end
