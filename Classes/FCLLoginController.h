
@class FCLSession;
@class FCLLoginController;

@protocol FCLLoginControllerDelegate <NSObject>

-(void) loginControllerWantsAccountCreation:(nonnull FCLLoginController *)controller;
-(void) loginControllerDidFail:(nonnull FCLLoginController *)controller error:(nonnull NSError *)error;

@end

@interface FCLLoginController : UITableViewController

-(nonnull instancetype) initWithDelegate:(nonnull id <FCLLoginControllerDelegate>)delegate email:(nullable NSString *)email;
@property (nullable, nonatomic) NSString *email;

@end
