
@class FCLSession;
@class FCLLoginViewController;

@protocol FCLLoginViewControllerDelegate <NSObject>

-(void) loginViewControllerWantsAccountCreation:(nonnull FCLLoginViewController *)controller;
-(void) loginViewControllerDidFail:(nonnull FCLLoginViewController *)controller error:(nonnull NSError *)error;

@end

@interface FCLLoginViewController : UITableViewController

-(nonnull instancetype) initWithDelegate:(nonnull id <FCLLoginViewControllerDelegate>)delegate email:(nullable NSString *)email;
@property (nullable, nonatomic) NSString *email;

@end
