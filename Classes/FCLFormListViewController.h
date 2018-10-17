#import "FCLUploader.h"
@class FCLFormListViewController;
@class FCLBusinessFile;

@protocol FCLFormListViewControllerDelegate <NSObject>

/// Informs the delegate that the businessFile must be refreshed. The property must be set (even to nil) for the Refresh Control to end refreshing.
-(void) formListViewControllerRefresh:(nonnull FCLFormListViewController *)controller;

@end

/// Presents the list of Scan forms
@interface FCLFormListViewController : UITableViewController

@property (nullable, weak) id <FCLFormListViewControllerDelegate> delegate;
@property (nullable, strong) FCLBusinessFile *businessFile;

@property (nonnull) NSString *username;
@property (nonnull) NSString *password;

@end
