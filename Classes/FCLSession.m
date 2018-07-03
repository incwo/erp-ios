#import "FCLSession.h"
#import "NSData+Base64.h"
#import "PXWWWFormSerialization.h"

NSString* const FCLSessionNeedsSignInNotification = @"FCLSessionNeedsSignInNotification";
NSString* const FCLSessionEmailKey = @"FCLSessionEmail";
NSString* const FCLSessionDidSignInNotification = @"FCLSessionDidSignInNotification";
NSString* const FCLSessionDidSignOutNotification = @"FCLSessionDidSignOutNotification";

@interface FCLSession ()
@end

@implementation FCLSession

+ (instancetype) savedSession
{
    FCLSession* session = [[self alloc] init];
    session.username = [[NSUserDefaults standardUserDefaults] objectForKey:@"FCLSessionUsername"];
    session.password = [[NSUserDefaults standardUserDefaults] objectForKey:@"FCLSessionPassword"];
    
    if (session.username.length > 0 && session.password.length > 0)
    {
        return session;
    }
    return nil;
}

+ (void) removeSavedSession
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FCLSessionUsername"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FCLSessionPassword"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FCLSessionDidSignOutNotification object:nil];
}

+ (NSString*) facileBaseURL
{
    return [([FCLSession savedSession] ?: [[FCLSession alloc] init]) facileBaseURL];
}

- (void) saveSession
{
    [[NSUserDefaults standardUserDefaults] setObject:self.username ?: @"" forKey:@"FCLSessionUsername"];
    [[NSUserDefaults standardUserDefaults] setObject:self.password ?: @"" forKey:@"FCLSessionPassword"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FCLSessionDidSignInNotification object:self];
}

- (BOOL) isValid
{
    return (self.username.length > 0 && self.password.length > 0);
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

- (void) setFCLSession:(FCLSession*)session
{
    NSData* data = [[NSString stringWithFormat:@"%@:%@", session.username, session.password] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSString* value = [@"Basic " stringByAppendingString:[data base64EncodedString]];
    [self setValue:value forHTTPHeaderField:@"Authorization"];
}

@end