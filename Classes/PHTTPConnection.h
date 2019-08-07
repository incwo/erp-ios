// PHTTPConnection acts as a thin wrapper for NSURLConnection.
// It mirrors all NSURLConnection delegate methods with the PHTTPConnection* methods.
//
// Define the PHTTPConnectionNetworkActivityStack macro to an object that implements the push and pop selectors (see PNetworkActivityStack)

// PHTTPConnectionErrorDomain (HTTP response code not in [200, 399]):
// - HTTP response code is error.code
// - NSData* sent by server is [error.userInfo objectForKey:PHTTPConnectionErrorResponseBodyDataKey];
extern NSString* const PHTTPConnectionErrorDomain;
extern NSString* const PHTTPConnectionErrorResponseBodyDataKey;

@class PHTTPConnection;
@protocol PHTTPConnectionDelegate<NSObject>
@optional
- (void) HTTPConnection:(PHTTPConnection*)aConnection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;
- (void) HTTPConnection:(PHTTPConnection*)aConnection didReceiveResponse:(NSURLResponse*)response;
- (void) HTTPConnection:(PHTTPConnection*)aConnection didReceiveData:(NSData*)data;
- (void) HTTPConnectionDidFinishLoading:(PHTTPConnection*)aConnection;
- (void) HTTPConnection:(PHTTPConnection*)aConnection didFailWithError:(NSError*)error;

- (NSURLRequest*) HTTPConnection:(PHTTPConnection*)aConnection willSendRequest:(NSURLRequest*)request redirectResponse:(NSURLResponse*)response;
- (NSInputStream*) HTTPConnection:(PHTTPConnection*)aConnection needNewBodyStream:(NSURLRequest*)request;
- (BOOL) HTTPConnection:(PHTTPConnection*)aConnection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace*)protectionSpace;
- (void) HTTPConnection:(PHTTPConnection*)aConnection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge;
- (void) HTTPConnection:(PHTTPConnection*)aConnection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge;
- (BOOL) HTTPConnectionShouldUseCredentialStorage:(PHTTPConnection*)aConnection;
- (NSCachedURLResponse*) HTTPConnection:(PHTTPConnection*)aConnection willCacheResponse:(NSCachedURLResponse*)cachedResponse;

// Will be called if a PHTTPConnection is initialized with a URL, not with a request.
// If this method is not implemented, [NSURLRequest requestWithURL:URL] is assumed.
- (NSURLRequest *)HTTPConnection:(PHTTPConnection*)aConnection requestForURL:(NSURL *)URL;
@end

@interface PHTTPConnection : NSObject <NSCoding>

#pragma mark - Building a PHTTPConnection

+ (id) connectionWithURL:(NSURL*)URL;
+ (id) connectionWithURL:(NSURL*)URL delegate:(id<PHTTPConnectionDelegate>)delegate;
+ (id) connectionWithRequest:(NSURLRequest*)request;
+ (id) connectionWithRequest:(NSURLRequest*)request delegate:(id<PHTTPConnectionDelegate>)delegate;


#pragma mark - Delegation and callbacks

@property(nonatomic, weak) id<PHTTPConnectionDelegate> delegate;

#pragma mark - Configuration

@property(nonatomic) NSURLRequest *request; // Behavior is undefined if you set request and URL.
@property(nonatomic) NSURL *URL; // Behavior is undefined if you set request and URL.
@property(nonatomic) NSString *username;
@property(nonatomic) NSString *password;
@property(nonatomic) NSUInteger byteOffset; // starting offset
@property(nonatomic) NSString *runLoopMode;
@property(nonatomic) BOOL doNotShowActivityIndicator;
@property(nonatomic) NSURL *targetFileURL;
@property(nonatomic ) NSArray *SSLTrustedHosts; // Defaults to [PHTTPConnection SSLTrustedHosts]. The list of hosts which should not trigger kCFURLErrorServerCertificateUntrusted


#pragma mark - Dynamic state

@property(nonatomic, readonly) NSData *data;
@property(nonatomic, readonly) NSHTTPURLResponse *lastResponse;
@property(nonatomic, readonly) NSError *error; // relevant if and only if data is nil
@property(nonatomic, readonly) double loadingProgress; // in [0,1]
@property(nonatomic, readonly) NSMutableDictionary *userDictionary;
@property(nonatomic, readonly) BOOL didConnect; // set to YES once a NSURLConnection has been initiated

typedef void (^PHTTPConnectionCompletion)(void);

// NSOperation-compatible APIs, with equivalent semantics:
@property (nonatomic, copy) PHTTPConnectionCompletion completionBlock; // Run once the connection is finished (see isFinished below)
@property(nonatomic, readonly, getter=isExecuting) BOOL executing; // NO if the connection has not been started or is already finished; otherwise, YES.
@property(nonatomic, readonly, getter=isCancelled) BOOL cancelled; // YES if the connection has been cancelled; otherwise, NO.
@property(nonatomic, readonly, getter=isFinished)  BOOL finished; // YES if the connection has completed, or has been cancelled; otherwise, NO.
- (void) start; // if the receiver was cancelled or is already finished, this method is a noop.
- (void) cancel; // if the receiver was cancelled or is already finished, this method is a noop.

// convenience method that sets the completionBlock and starts the connection.
- (void) startWithCompletionBlock:(PHTTPConnectionCompletion)aBlock;
@end
