
@class FCLSession;
@class FCLLoginViewController;

@protocol FCLLoginViewControllerDelegate <NSObject>

-(void) loginViewControllerWantsAccountCreation:(nonnull FCLLoginViewController *)controller;

@end

@interface FCLLoginViewController : UITableViewController

@property (nullable, weak) id <FCLLoginViewControllerDelegate> delegate;
@property (nullable, nonatomic) NSString *email;

@end
