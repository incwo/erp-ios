
@class FCLSession;
@class FCLOfficeContentViewController;

@protocol FCLOfficeContentViewControllerDelegate <NSObject>

-(void) officeContentViewControllerPresentSidePanel:(nonnull FCLOfficeContentViewController *)controller;
-(void) officeContentViewController:(nonnull FCLOfficeContentViewController *)controller didPresentURL:(nonnull NSURL *)url;

@end

@interface FCLOfficeContentViewController : UIViewController

@property (nullable, weak) id <FCLOfficeContentViewControllerDelegate> delegate;
@property (nonnull, nonatomic) FCLSession* session;

-(void) loadHomepage;
-(void) loadBusinessFileWithId:(nonnull NSString *)businessFileId;
-(nullable NSURL *)currentURL;

@end
