
extern NSString * _Nonnull const FCLSessionNeedsSignInNotification;
extern NSString * _Nonnull const FCLSessionEmailKey;  // optional email stored in FCLSessionNeedsSignInNotification
extern NSString * _Nonnull const FCLSessionDidSignInNotification;
extern NSString * _Nonnull const FCLSessionDidSignOutNotification;

@interface FCLSession : NSObject

-(nonnull instancetype) initWithUsername:(nonnull NSString *)username password:(nonnull NSString *)password shard:(nullable NSString *)shard;
@property (nonnull, atomic, readonly) NSString* username;
@property (nonnull, atomic, readonly) NSString* password;
@property (nullable, atomic, readonly) NSString *shard;
-(nonnull instancetype)init NS_UNAVAILABLE;

+ (nullable instancetype) savedSession;
+ (void) removeSavedSession;
- (void) saveSession;

/// The base URL, composed as to take the .shard into account.
- (nonnull NSString *) baseURL;

/// The base URL, for when the user is not authenticated (e.g. to create a new account).
+ (nonnull NSString *) unauthenticatedBaseURL;

+ (nonnull NSURLRequest *)signupRequest;
@end

@interface NSMutableURLRequest (FCLSession)
- (void) setBasicAuthHeadersForSession:(nonnull FCLSession *)session;
@end
