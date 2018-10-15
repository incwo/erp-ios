
@class FCLCategory;
@class FCLFormController;

@protocol FCLFormViewControllerDelegate <NSObject>

-(void) formViewControllerSend:(FCLFormController *)controller;

@end

@interface FCLFormController : UITableViewController

@property (nonatomic, weak) id <FCLFormViewControllerDelegate> delegate;
@property(nonatomic, strong) FCLCategory* category;
@property(nonatomic, strong) UIImage* image;

- (NSArray*) fields;

@end
