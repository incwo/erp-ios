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
    NSString *username = [[self class] savedUsername];
    NSString *password = [[self class] savedPassword];
    
    if (username.length > 0 && password.length > 0) {
        return [[FCLSession alloc] initWithUsername:username password:password];
    } else {
        return nil;
    }
}

+ (void) removeSavedSession {
    [[self class] removeCredentials];
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

- (void) saveSession {
    [[self class] saveUsername:self.username password:self.password];
    [[NSNotificationCenter defaultCenter] postNotificationName:FCLSessionDidSignInNotification object:self];
}

- (NSString*) facileBaseURL {
    NSArray *devAccounts = @[@"guillaume.besse@gmail.com"];
    if ([devAccounts containsObject:[self.username lowercaseString]]) {
        return FACILE_BASEURL_DEV;
    } else {
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

// MARK: Storing Credentials

+(NSURLProtectionSpace *) protectionSpace {
    static dispatch_once_t onceToken;
    static NSURLProtectionSpace *protectionSpace = nil;
    dispatch_once(&onceToken, ^{
        protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:@"incwo.com" port:80 protocol:@"https" realm:nil authenticationMethod:NSURLAuthenticationMethodHTTPBasic];
    });
    return protectionSpace;
}

+(void) saveUsername:(NSString *)username password:(NSString *)password {
    NSURLCredential *credential = [[NSURLCredential alloc] initWithUser:username password:password persistence:NSURLCredentialPersistencePermanent];
    [[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential:credential forProtectionSpace:[self protectionSpace]];
}

+(NSString *) savedUsername {
    NSURLCredential *credential = [[NSURLCredentialStorage sharedCredentialStorage] defaultCredentialForProtectionSpace:[self protectionSpace]];
    return credential.user;
}

+(NSString *) savedPassword {
    NSURLCredential *credential = [[NSURLCredentialStorage sharedCredentialStorage] defaultCredentialForProtectionSpace:[self protectionSpace]];
    return credential.password;
}

+(void) removeCredentials {
    NSURLCredential *credential = [[NSURLCredentialStorage sharedCredentialStorage] defaultCredentialForProtectionSpace:[self protectionSpace]];
    [[NSURLCredentialStorage sharedCredentialStorage] removeCredential:credential forProtectionSpace:[self protectionSpace]];
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
