#import "FCLSession.h"
#import "PXWWWFormSerialization.h"

NSString* const FCLSessionNeedsSignInNotification = @"FCLSessionNeedsSignInNotification";
NSString* const FCLSessionEmailKey = @"FCLSessionEmail";
NSString* const FCLSessionDidSignInNotification = @"FCLSessionDidSignInNotification";
NSString* const FCLSessionDidSignOutNotification = @"FCLSessionDidSignOutNotification";

@interface FCLSession ()
@end

@implementation FCLSession

-(nonnull instancetype) initWithUsername:(nonnull NSString *)username password:(nonnull NSString *)password {
    self = [super init];
    if (self) {
        NSParameterAssert(username);
        _username = username;
        NSParameterAssert(password);
        _password = password;
    }
    return self;
}

+ (instancetype) savedSession {
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"FCLSessionUsername"];
    NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:@"FCLSessionPassword"];
    
    if (username.length > 0 && password.length > 0) {
        return [[FCLSession alloc] initWithUsername:username password:password];
    } else {
        return nil;
    }
}

+ (void) removeSavedSession
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FCLSessionUsername"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FCLSessionPassword"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FCLSessionDidSignOutNotification object:nil];
}

+ (NSString*) facileBaseURL {
    FCLSession *savedSession = [FCLSession savedSession];
    if(savedSession) {
        return [savedSession facileBaseURL];
    } else {
        return FACILE_BASEURL;
    }
}

- (void) saveSession
{
    [[NSUserDefaults standardUserDefaults] setObject:self.username ?: @"" forKey:@"FCLSessionUsername"];
    [[NSUserDefaults standardUserDefaults] setObject:self.password ?: @"" forKey:@"FCLSessionPassword"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FCLSessionDidSignInNotification object:self];
}

- (NSString*) facileBaseURL
{
    if ([self.username.lowercaseString isEqualToString:@"guillaume.besse@gmail.com"])
    {
        return FACILE_BASEURL_DEV;
    }
    else
    {
        return FACILE_BASEURL;
    }
}

+ (NSURLRequest *)signupRequest
{
    NSString *bundleID = [[NSBundle mainBundle].infoDictionary objectForKey:(NSString *)kCFBundleIdentifierKey];
    NSDictionary *parameters = @{ @"bundle_id": bundleID };
    NSString *queryString = [PXWWWFormSerialization stringWithDictionary:parameters options:0];
    return [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/iframe/pos_new_account?%@", [self facileBaseURL], queryString]]];
}

@end










@implementation NSMutableURLRequest (FCLSession)

- (void) setFCLSession:(nonnull FCLSession *)session
{
    NSData* data = [[NSString stringWithFormat:@"%@:%@", session.username, session.password] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSString* value = [@"Basic " stringByAppendingString:[data base64EncodedStringWithOptions:0]];
    [self setValue:value forHTTPHeaderField:@"Authorization"];
}

@end
