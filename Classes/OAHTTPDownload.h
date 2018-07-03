#import "OAHTTPProtocols.h"

@interface OAHTTPDownload : NSObject <OAHTTPDownload, NSCoding>

@property(nonatomic,strong) NSURLRequest*  request;
@property(nonatomic,strong) NSMutableData* receivedData;
@property(nonatomic,strong) NSString*      username;
@property(nonatomic,strong) NSString*      password;
@property(nonatomic,assign) NSUInteger     numberOfAuthenticationAttempts;

@property(nonatomic,strong) NSURLConnection* connection;
@property(nonatomic,strong) NSHTTPURLResponse* lastResponse;

@property(nonatomic,weak) id<OAHTTPDownloadDelegate> delegate;
@property(nonatomic,weak) id<OAHTTPQueue> queue;

@property(nonatomic,weak) id target;
@property(nonatomic,assign) SEL successAction;
@property(nonatomic,assign) SEL failureActionWithError;

@property(nonatomic,assign) BOOL shouldAllowSelfSignedCert;

- (void) setURL:(NSURL*)url; 

- (void) didFinishLoading;
- (void) didFailWithError:(NSError*)error;

@end
