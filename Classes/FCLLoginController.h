
@class FCLSession;
@interface FCLLoginController : UITableViewController
@property(nonatomic, copy) NSString *email;
@property(nonatomic, copy) void(^completionHandler)(FCLSession*, NSError*);

@end
