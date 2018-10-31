
@class FCLSession;
@class FCLLoginViewController;

@protocol FCLLoginViewControllerDelegate <NSObject>

-(void) loginViewControllerWantsAccountCreation:(nonnull FCLLoginViewController *)controller;

@end

@interface FCLLoginViewController : UITableViewController

-(nonnull instancetype) initWithDelegate:(nonnull id <FCLLoginViewControllerDelegate>)delegate email:(nullable NSString *)email;
@property (nullable, nonatomic) NSString *email;

@end
