
@class FCLSession;
@interface FCLLoginController : UITableViewController

typedef void (^FCLLoginControllerSuccessHandler)(FCLSession * _Nonnull session);
typedef void (^FCLLoginControllerFailureHandler)(NSError * _Nonnull error);

-(nonnull instancetype) initWithEMail:(nullable NSString *)email success:(nonnull FCLLoginControllerSuccessHandler)successHandler failure:(nonnull FCLLoginControllerFailureHandler)failureHandler;

@end
