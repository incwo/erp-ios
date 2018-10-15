#import "FCLUploader.h"
@class FCLScanCategoriesController;
@class FCLBusinessFile;

@protocol FCLScanCategoriesControllerDelegate <NSObject>

/// Informs the delegate that the businessFile must be refreshed. The property must be set (even to nil) for the Refresh Control to end refreshing.
-(void) scanCategoriesControllerRefresh:(nonnull FCLScanCategoriesController *)controller;

@end

/// Presents the list of Scan forms
@interface FCLScanCategoriesController : UITableViewController

@property (nullable, weak) id <FCLScanCategoriesControllerDelegate> delegate;
@property (nullable, strong) FCLBusinessFile *businessFile;

@property (nonnull) NSString *username;
@property (nonnull) NSString *password;

@end
