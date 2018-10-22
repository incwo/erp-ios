@class FCLBusinessFilesViewController;
@class FCLFormsBusinessFile;

@protocol FCLBusinessFilesViewControllerDelegate

/// The controller wants the list of business files to be refreshed, either because the user did a "Pull to refresh" or because the same list was shown for too long.
-(void) businessFilesViewControllerRefresh:(nonnull FCLBusinessFilesViewController *)controller;

-(void) businessFilesViewController:(nonnull FCLBusinessFilesViewController *)controller didSelectBusinessFile:(nonnull FCLFormsBusinessFile *)businessFile;

-(void) businessFilesViewControllerLogOut:(nonnull FCLBusinessFilesViewController *)controller;

@end

@interface FCLBusinessFilesViewController : UITableViewController

-(nonnull instancetype) initWithDelegate:(nonnull id <FCLBusinessFilesViewControllerDelegate>)delegate;

// Must be passed 'nil' on errors, to indicate the end of loading (to hide the Refresh Control)
@property (nullable) NSArray <FCLFormsBusinessFile *> *businessFiles;

@end
