
@class FCLSession;
@interface FCLLoginController : UITableViewController

typedef void (^FCLLoginControllerSuccessHandler)(FCLSession * _Nullable session); // session is nil if cancelled
typedef void (^FCLLoginControllerFailureHandler)(NSError * _Nonnull error);

-(nonnull instancetype) initWithEMail:(nullable NSString *)email success:(nonnull FCLLoginControllerSuccessHandler)successHandler failure:(nonnull FCLLoginControllerFailureHandler)failureHandler;

@end
