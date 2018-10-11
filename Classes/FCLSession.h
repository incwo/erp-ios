
extern NSString * _Nonnull const FCLSessionNeedsSignInNotification;
extern NSString * _Nonnull const FCLSessionEmailKey;  // optional email stored in FCLSessionNeedsSignInNotification
extern NSString * _Nonnull const FCLSessionDidSignInNotification;
extern NSString * _Nonnull const FCLSessionDidSignOutNotification;

@interface FCLSession : NSObject

-(nonnull instancetype) initWithUsername:(nonnull NSString *)username password:(nonnull NSString *)password;
@property (nonnull, atomic, readonly) NSString* username;
@property (nonnull, atomic, readonly) NSString* password;
-(nonnull instancetype)init NS_UNAVAILABLE;

+ (nullable instancetype) savedSession;
+ (void) removeSavedSession;
- (void) saveSession;
- (nonnull NSString *) facileBaseURL;
+ (nonnull NSString *) facileBaseURL;

+ (nonnull NSURLRequest *)signupRequest;
@end

@interface NSMutableURLRequest (FCLSession)
- (void) setFCLSession:(nonnull FCLSession *)session;
@end
