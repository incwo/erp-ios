@protocol OAHTTPDownload;

/*
Rejection from AppStore: 26.01.2010 (Entrepreneur application)
 
The non-public API that is included in your application is download:didReceiveResponse:.

If you have defined a method in your source code with the same name as the above mentioned API, we suggest altering your method name so that it no longer collides with Apple's private API to avoid your application being flagged with future submissions.

Regards,

iPhone Developer Program
*/
@protocol OAHTTPDownloadDelegate <NSObject>
- (void) oadownloadDidFinishLoading:(id<OAHTTPDownload>)download;
- (void) oadownload:(id<OAHTTPDownload>)download didFailWithError:(NSError *)error;
@optional
- (void) oadownload:(id<OAHTTPDownload>)download didReceiveResponse:(NSHTTPURLResponse *)response;
- (void) oadownload:(id<OAHTTPDownload>)download didReceiveData:(NSData *)chunk;
- (BOOL) oadownload:(id<OAHTTPDownload>)download shouldHandleAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
@end


@protocol OAHTTPQueue <NSObject, OAHTTPDownloadDelegate, NSCoding>

- (void) addOperation:(NSOperation*)op;

- (id<OAHTTPDownload>) currentDownload;

- (id<OAHTTPDownloadDelegate>) delegate;
- (void) setDelegate:(id<OAHTTPDownloadDelegate>) delegate;
- (id<OAHTTPDownloadDelegate>) downloadDelegate;
- (void) setDownloadDelegate:(id<OAHTTPDownloadDelegate>) downloadDelegate;

- (void) pushPause;
- (void) popPause;

- (void) appendDownload:(id<OAHTTPDownload>) download;
- (void) appendDownloadOnce:(id<OAHTTPDownload>) download;
- (void) appendDownloadOnce:(id<OAHTTPDownload>) download withStackLimit:(NSUInteger)limit;
- (void) prependDownload:(id<OAHTTPDownload>) download;
- (void) prependDownloadOnce:(id<OAHTTPDownload>) download;
- (void) prependDownloadOnce:(id<OAHTTPDownload>) download withStackLimit:(NSUInteger)limit;

- (void) removeDownload:(id<OAHTTPDownload>) download;

- (void) cancelCurrentDownload;
- (void) cancelAllDownloads;

- (BOOL) isNetworkError:(NSError*)error;
- (NSData*) receivedData;

- (void) proceed; // used when initialized with coder to proceed operations after delegates are set etc.
@end


@protocol OAHTTPDownload <NSObject>

+ (id) download;
+ (id) downloadWithRequest:(NSURLRequest*)request;
+ (id) downloadWithURL:(NSURL*)url;

- (id<OAHTTPQueue>) queue;
- (void) setQueue:(id<OAHTTPQueue>) queue;
- (id<OAHTTPDownloadDelegate>) delegate;
- (void) setDelegate:(id<OAHTTPDownloadDelegate>) delegate;
- (NSData*) receivedData;

- (NSString*) username;
- (void) setUsername:(NSString*) username;
- (NSString*) password;
- (void) setPassword:(NSString*) password;

- (NSURLRequest*) request;
- (NSURL*) URL;

- (float) loadingProgress;

- (void) start;
- (void) cancel;

- (void) reset;

@end
