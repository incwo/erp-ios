
// This is not a UITableViewController, because there is a need to overlay the table with a transparent black overlay while searching
@interface FCLVideosViewController : UIViewController

+ (instancetype) catalogController;
+ (instancetype) videosControllerWithVideoItems:(NSArray*)videoItems title:(NSString*)title;

@end
