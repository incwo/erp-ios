#import "FCLUploader.h"

@class FCLForm;
@class FCLFormListViewController;
@class FCLFormsBusinessFile;

@protocol FCLFormListViewControllerDelegate <NSObject>

-(void) formListViewControllerSidePanel:(nonnull FCLFormListViewController *)controller;

/// Informs the delegate that the businessFile must be refreshed. The property must be set (even to nil) for the Refresh Control to end refreshing.
-(void) formListViewControllerRefresh:(nonnull FCLFormListViewController *)controller;

-(void) formListViewController:(nonnull FCLFormListViewController *)controller didSelectForm:(nonnull FCLForm *)form;

@end

/// Presents the list of Scan forms
@interface FCLFormListViewController : UITableViewController

@property (nullable, weak) id <FCLFormListViewControllerDelegate> delegate;
@property (nullable, strong) NSString *businessFileName;
@property (nullable, strong) NSArray *formsAndFolders; // FCLForms and FCLFormFolders

@end
