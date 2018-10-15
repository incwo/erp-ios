
@class FCLCategory;
@class FCLFormViewController;

@protocol FCLFormViewControllerDelegate <NSObject>

/// The "Send" button was tapped.
-(void) formViewControllerSend:(FCLFormViewController *)controller;

@end

@interface FCLFormViewController : UITableViewController

@property (nonatomic, weak) id <FCLFormViewControllerDelegate> delegate;
@property(nonatomic, strong) FCLCategory* category;
@property(nonatomic, strong) UIImage* image;

- (NSArray*) fields;

@end
