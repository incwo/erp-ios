
@class FCLField;
@class FCLOptionsViewController;

@protocol FCLOptionsViewControllerDelegate <NSObject>

-(void) optionsViewControllerDidPick:(FCLOptionsViewController *)controller;

@end

/// TableViewController to pick among a list of options
@interface FCLOptionsViewController : UITableViewController

@property (nonatomic, weak) id <FCLOptionsViewControllerDelegate> delegate;
@property(nonatomic, strong) FCLField* field;

@end
