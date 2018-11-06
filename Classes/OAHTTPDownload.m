#import "OAHTTPDownload.h"
#import "OANetworkActivityIndicator.h"

@implementation OAHTTPDownload {
    BOOL isActive;
}


#pragma mark Init

+ (instancetype) download
{
    return [[self alloc] init];
}

+ (instancetype) downloadWithRequest:(NSURLRequest*)request
{
    OAHTTPDownload* download = [self download];
    [download setRequest:request];
    return download;
}

+ (instancetype) downloadWithURL:(NSURL*)url;
{
    OAHTTPDownload* download = [self download];
    [download setURL:url];
    return download;
}

- (void) reset
{
    _numberOfAuthenticationAttempts = 3;
    self.request = nil;
    self.receivedData = nil;
    self.username = nil;
    self.password = nil;
    self.connection = nil;
    self.lastResponse = nil;
    self.queue = nil;
    self.delegate = nil;
}

- (id) init
{
    if (self = [super init])
    {
        [self reset];
	}
	return self;
}

- (void) dealloc
{
    [self cancel];
    [self reset];
}




#pragma mark Comparison


-(BOOL) isEqual:(id)other
{
    return [other conformsToProtocol:@protocol(OAHTTPDownloadProtocol)] && [[self URL] isEqual:[other URL]];
}

-(NSUInteger) hash
{
    return [[self URL] hash];
}



#pragma mark NSCoding


- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    [self reset];
    self.request = [coder decodeObjectForKey:@"request"];
    self.username = [coder decodeObjectForKey:@"username"];
    self.password = [coder decodeObjectForKey:@"password"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_request forKey:@"request"];
    [coder encodeObject:_username forKey:@"username"];
    [coder encodeObject:_password forKey:@"password"];
}



#pragma mark API


- (NSURL*) URL
{
    return [_request URL];
}

- (void) setURL:(NSURL*)url
{
    self.request = [NSURLRequest requestWithURL:url];
}

- (void) start
{
    if (!isActive)
    {
        isActive = YES;
        [OANetworkActivityIndicator push];
    }
    self.connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self];
}

- (void) cancel
{
    if (isActive)
    {
        isActive = NO;
        [OANetworkActivityIndicator pop];
    }
    [self.connection cancel];
    self.connection = nil;
}

- (float) loadingProgress
{
    if (_lastResponse &&
        [_lastResponse expectedContentLength] != NSURLResponseUnknownLength &&
        _receivedData)
    {
        float contentLength = (float) [_lastResponse expectedContentLength];
        float dataLength = (float)[_receivedData length];
        if (contentLength > 0.000001)
        {
            return dataLength / contentLength;
        }
    }
    return (float)0.0;
}




#pragma mark Logging


- (void) log:(NSString*)msg
{
    NSLog(@"OAHTTPDownload: %@ [%@]", msg, [[_request URL] absoluteString]);
}

- (void) logError:(NSError*)error
{
    [self log:[error localizedDescription]];
}


#pragma mark Proxy callbacks (can be overriden by subclasses)


- (void) didFinishLoading
{
    if (isActive)
    {
        isActive = NO;
        [OANetworkActivityIndicator pop];
    }
    
    [self.delegate oadownloadDidFinishLoading:self];

    [_queue oadownloadDidFinishLoading:self];
}

- (void) didFailWithError:(NSError*)error
{
    if (isActive)
    {
        isActive = NO;
        [OANetworkActivityIndicator pop];
    }
    [_delegate oadownload:self didFailWithError:error];
    [_queue oadownload:self didFailWithError:error];
}


#pragma mark NSURLConnection callbacks


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self didFailWithError:error];
}

// Note: this method does not take advantage of proposedCredential and persistant credentials yet.
// AFAIK, iphone does not support that api yet.
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (![_delegate respondsToSelector:@selector(oadownload:shouldHandleAuthenticationChallenge:)] ||
        [_delegate oadownload:self shouldHandleAuthenticationChallenge:challenge])
    {
        if (_username != nil && _password != nil)
        {
            if (_numberOfAuthenticationAttempts > 0)
            {
                _numberOfAuthenticationAttempts--;
                NSURLCredential* credential = [NSURLCredential credentialWithUser:_username password:_password persistence:NSURLCredentialPersistenceNone];
                [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
            }
            else
            {
                [self log:@"exceeded number of authentication attempts; proceeding without credentials"];
                [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
            }
        }
        else
        {
            [self log:@"received authentication challenge, but username or password is nil; proceeding without credentials"];
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
        }
    }
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)space
{
    if([[space authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        if (_shouldAllowSelfSignedCert)
        {
            return YES; // Self-signed cert will be accepted
        } else {
            return NO;  // Self-signed cert will be rejected
        }
        // Note: it doesn't seem to matter what you return for a proper SSL cert
        //       only self-signed certs
    }
    // If no other authentication is required, return NO for everything else
    // Otherwise maybe YES for NSURLAuthenticationMethodDefault and etc.
    return NO;
}

// Note: this method is called once per mime type; it should reset received data appropriately
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.lastResponse = (NSHTTPURLResponse*)response;
    if (self.receivedData != nil)
    {
        [self log:@"didReceiveResponse: data is not nil => multipart download detected; resetting data"];
    }
    self.receivedData = [NSMutableData data];
    if ([_delegate respondsToSelector:@selector(oadownload:didReceiveResponse:)])
        [_delegate oadownload:self didReceiveResponse:self.lastResponse];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)chunk
{
    [_receivedData appendData:chunk];
    if ([_delegate respondsToSelector:@selector(oadownload:didReceiveData:)])
        [_delegate oadownload:self didReceiveData:chunk];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSInteger code = (_lastResponse ? [_lastResponse statusCode] : 0);
    if (code >= 200 && code <= 299)
    {
        [self didFinishLoading];
    }
    else
    {
        NSError* error = [NSError errorWithDomain:@"HTTP" code:code userInfo:nil];
        [self didFailWithError:error];
    }
}


@end
