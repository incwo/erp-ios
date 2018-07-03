
@class FCLField;

/// TableViewController to pick among a list of options
@interface FCLOptionsController : UITableViewController

@property(nonatomic, strong) FCLField* field;

// WTF: Target-action is used to provide the parent View controller with data
@property(nonatomic, weak) id target;
@property(nonatomic, assign) SEL action;

@end
