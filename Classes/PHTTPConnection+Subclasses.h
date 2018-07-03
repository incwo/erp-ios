// PHTTPConnection acts as a thin wrapper for NSURLConnection.
// It mirrors all NSURLConnection delegate methods with the PHTTPConnection* methods.
//
// Define the PHTTPConnectionNetworkActivityStack macro to an object that implements the push and pop selectors (see PNetworkActivityStack)

#import "PHTTPConnection.h"

@interface PHTTPConnection(Subclasses)

@property(nonatomic,copy) NSData* data;
@property(nonatomic,retain) NSError* error;

// Subclasses must not call, may override, and may not call super
// Returns a NSURLRequest suitable for URL
- (void) connect;

// Subclasses must not call, may override, and may not call super
// Subclasses have this last chance to setup the NSURLRequest actually sent
- (NSURLRequest*) willSendInitialRequest:(NSURLRequest*)request;

// Subclasses may call, but must not override
- (void)finish;

// Subclasses must not call, may override, and must not call super
- (void) didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;

// Subclasses must not call, may override, and must not call super
- (void) didReceiveResponse:(NSURLResponse*)response;

// Subclasses must not call, may override, and must not call super
- (void) didReceiveData:(NSData*)data;

// Subclasses must not call, may override, and must not call super
- (void) didFinishLoading;

// Subclasses must not call, may override, and must not call super
- (void) didFailWithError:(NSError*)error;

// Subclasses must not call, may override, and must not call super
- (void) didFinish;

// Subclasses must not call, may override, and must call super
// Implementations is replaced by the delegate implemention, if any.
- (NSURLRequest*) willSendRequest:(NSURLRequest*)request redirectResponse:(NSURLResponse*)response;

// Subclasses must not call, may override, and must call super
// Implementations is replaced by the delegate implemention, if any.
- (NSInputStream*) needNewBodyStream:(NSURLRequest*)request;

// Subclasses must not call, may override, and must call super
// Implementations is replaced by the delegate implemention, if any.
- (BOOL) canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace*)protectionSpace;

// Subclasses must not call, may override, and must call super
// Implementations is replaced by the delegate implemention, if any.
- (void) didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge;

// Subclasses must not call, may override, and must call super
// Implementations is replaced by the delegate implemention, if any.
- (void) didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge;

// Subclasses must not call, may override, and must call super
// Implementations is replaced by the delegate implemention, if any.
- (BOOL) shouldUseCredentialStorage;

// Subclasses must not call, may override, and must call super
// Implementations is replaced by the delegate implemention, if any.
- (NSCachedURLResponse*) willCacheResponse:(NSCachedURLResponse*)cachedResponse;

@end
