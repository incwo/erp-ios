
@class FCLCategory;
@interface FCLFormController : UITableViewController

@property(nonatomic, strong) FCLCategory* category;
@property(nonatomic, strong) UIImage* image;

- (NSArray*) fields;

// WTF: Target-action is used to provide the parent View controller with data
@property(nonatomic, weak) id target;
@property(nonatomic, assign) SEL action;

@end
