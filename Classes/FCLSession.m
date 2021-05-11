#import "FCLSession.h"
#import "PXWWWFormSerialization.h"

NSString* const FCLSessionNeedsSignInNotification = @"FCLSessionNeedsSignInNotification";
NSString* const FCLSessionEmailKey = @"FCLSessionEmail";
NSString* const FCLSessionDidSignInNotification = @"FCLSessionDidSignInNotification";
NSString* const FCLSessionDidSignOutNotification = @"FCLSessionDidSignOutNotification";

NSString* const FCLSessionShardKey = @"FCLSessionShard";

@interface FCLSession ()
@end

@implementation FCLSession

-(nonnull instancetype) initWithUsername:(nonnull NSString *)username password:(nonnull NSString *)password shard:(nullable NSString *)shard {
    self = [super init];
    if (self) {
        NSParameterAssert(username);
        _username = username;
        NSParameterAssert(password);
        _password = password;
        
        if(shard.length == 0) shard = nil;
        _shard = shard;
    }
    return self;
}

+ (instancetype) savedSession {
    // In versions prior to 2.8, credentials were stored in NSUserDefaults. Which was terrible.
    // This is our chance to read them and erase them for good.
    // We should get rid of this code someday, when we consider that most users had the chance
    // to switch from the old to the new system.
    NSString *userDefaultsUsername = [[NSUserDefaults standardUserDefaults] objectForKey:@"FCLSessionUsername"];
    NSString *userDefaultsPassword = [[NSUserDefaults standardUserDefaults] objectForKey:@"FCLSessionPassword"];
    NSString *shard = [self savedShard];
    if(userDefaultsUsername.length > 0 && userDefaultsPassword.length > 0) {
        [[self class] saveUsername:userDefaultsUsername password:userDefaultsPassword shard:shard];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FCLSessionUsername"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FCLSessionPassword"];
    }
    
    NSString *username = [[self class] savedUsername];
    NSString *password = [[self class] savedPassword];
    if (username.length > 0 && password.length > 0) {
        return [[FCLSession alloc] initWithUsername:username password:password shard:shard];
    } else {
        return nil;
    }
}

+ (void) removeSavedSession {
    [[self class] removeCredentials];
    [[NSNotificationCenter defaultCenter] postNotificationName:FCLSessionDidSignOutNotification object:nil];
}

- (NSString *) baseURL {
    if(self.shard) {
        if([self.shard isEqualToString:@"dev"]) {
            return @"http://dev.incwo.com";
        } else {
            return [NSString stringWithFormat:@"https://%@.incwo.com", self.shard];
        }
    } else {
        return @"https://www.incwo.com";
    }
}

+ (NSString *) unauthenticatedBaseURL {
    return @"https://www.incwo.com";
}

- (void) saveSession {
    [[self class] saveUsername:self.username password:self.password shard:self.shard];
    [[NSNotificationCenter defaultCenter] postNotificationName:FCLSessionDidSignInNotification object:self];
}



+ (NSURLRequest *)signupRequest
{
    NSString *bundleID = [[NSBundle mainBundle].infoDictionary objectForKey:(NSString *)kCFBundleIdentifierKey];
    NSDictionary *parameters = @{ @"bundle_id": bundleID };
    NSString *queryString = [PXWWWFormSerialization stringWithDictionary:parameters options:0];
    return [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/iframe/pos_new_account?%@", [self unauthenticatedBaseURL], queryString]]];
}

// MARK: Storing Credentials

+(NSURLProtectionSpace *) protectionSpace {
    static dispatch_once_t onceToken;
    static NSURLProtectionSpace *protectionSpace = nil;
    dispatch_once(&onceToken, ^{
        protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:@"incwo.com" port:80 protocol:@"https" realm:nil authenticationMethod:NSURLAuthenticationMethodHTTPBasic];
    });
    return protectionSpace;
}

+(void) saveUsername:(NSString *)username password:(NSString *)password shard:(NSString *)shard {
    NSURLCredential *credential = [[NSURLCredential alloc] initWithUser:username password:password persistence:NSURLCredentialPersistencePermanent];
    [[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential:credential forProtectionSpace:[self protectionSpace]];
    
    [[NSUserDefaults standardUserDefaults] setValue:shard forKey:FCLSessionShardKey];
}

+(NSString *) savedUsername {
    NSURLCredential *credential = [[NSURLCredentialStorage sharedCredentialStorage] defaultCredentialForProtectionSpace:[self protectionSpace]];
    return credential.user;
}

+(NSString *) savedPassword {
    NSURLCredential *credential = [[NSURLCredentialStorage sharedCredentialStorage] defaultCredentialForProtectionSpace:[self protectionSpace]];
    return credential.password;
}

+(NSString *) savedShard {
    return [[NSUserDefaults standardUserDefaults] valueForKey:FCLSessionShardKey];
}

+(void) removeCredentials {
    NSURLCredential *credential = [[NSURLCredentialStorage sharedCredentialStorage] defaultCredentialForProtectionSpace:[self protectionSpace]];
    [[NSURLCredentialStorage sharedCredentialStorage] removeCredential:credential forProtectionSpace:[self protectionSpace]];
    
    [[NSUserDefaults standardUserDefaults] setValue:nil forKey:FCLSessionShardKey];
}

@end


@implementation NSMutableURLRequest (FCLSession)

- (void) setBasicAuthHeadersForSession:(nonnull FCLSession *)session
{
    NSData* data = [[NSString stringWithFormat:@"%@:%@", session.username, session.password] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSString* value = [@"Basic " stringByAppendingString:[data base64EncodedStringWithOptions:0]];
    [self setValue:value forHTTPHeaderField:@"Authorization"];
}

@end
