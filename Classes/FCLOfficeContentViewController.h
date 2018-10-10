
@class FCLSession;
@class FCLOfficeContentViewController;

@protocol FCLOfficeContentViewControllerDelegate <NSObject>

-(void) officeContentViewControllerDidLogOut:(FCLOfficeContentViewController *)controller;

@end

@interface FCLOfficeContentViewController : UIViewController

@property (nonatomic, weak) id <FCLOfficeContentViewControllerDelegate> delegate;
@property(nonatomic) FCLSession* session;

@end
