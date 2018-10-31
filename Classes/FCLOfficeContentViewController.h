
@class FCLSession;
@class FCLOfficeContentViewController;

@protocol FCLOfficeContentViewControllerDelegate <NSObject>

-(void) officeContentViewControllerPresentSidePanel:(nonnull FCLOfficeContentViewController *)controller;
-(void) officeContentViewController:(nonnull FCLOfficeContentViewController *)controller didPresentURL:(nonnull NSURL *)url;

@end

@interface FCLOfficeContentViewController : UIViewController

@property (nullable, weak) id <FCLOfficeContentViewControllerDelegate> delegate;
@property (nonnull, nonatomic) FCLSession* session;

/// The id of the business file to show in the webview.
@property (nullable) NSString *businessFileId;

@end
