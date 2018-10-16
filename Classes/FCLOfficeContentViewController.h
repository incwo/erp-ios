
@class FCLSession;
@class FCLOfficeContentViewController;

@protocol FCLOfficeContentViewControllerDelegate <NSObject>

-(void) officeContentViewController:(nonnull FCLOfficeContentViewController *)controller didPresentURL:(nonnull NSURL *)url;

@end

@interface FCLOfficeContentViewController : UIViewController

@property (nullable, weak) id <FCLOfficeContentViewControllerDelegate> delegate;
@property (nonnull, nonatomic) FCLSession* session;

@end
