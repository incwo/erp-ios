
extern NSString* const FCLSessionNeedsSignInNotification;
extern NSString* const FCLSessionEmailKey;  // optional email stored in FCLSessionNeedsSignInNotification
extern NSString* const FCLSessionDidSignInNotification;
extern NSString* const FCLSessionDidSignOutNotification;

@interface FCLSession : NSObject
@property(nonatomic) NSString* username;
@property(nonatomic) NSString* password;

+ (instancetype) savedSession;
+ (void) removeSavedSession;
- (void) saveSession;
- (BOOL) isValid;
- (NSString*) facileBaseURL;
+ (NSString*) facileBaseURL;

+ (NSURLRequest *)signupRequest;
@end

@interface NSMutableURLRequest (FCLSession)
- (void) setFCLSession:(FCLSession*)session;
@end
