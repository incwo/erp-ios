#import "PHTTPConnection.h"
#import "PHTTPConnection+Subclasses.h"

// This is to setup usage of one of the objects: OANetworkActivityIndicator or PNetworkActivityStack
#if !defined(PHTTPConnectionNetworkActivityStack)
#define PHTTPConnectionNetworkActivityStack (id<PHTTPConnectionNetworkActivityStackProtocol>)nil
#endif

@protocol PHTTPConnectionNetworkActivityStackProtocol
- (void) push;
- (void) pop;
@end

NSString* const PHTTPConnectionErrorDomain = @"PHTTPConnectionErrorDomain";
NSString* const PHTTPConnectionErrorResponseBodyDataKey = @"PHTTPConnectionErrorResponseBodyDataKey";

@interface PHTTPConnection ()
@property (nonatomic) NSURLConnection *connection;
@property (nonatomic) NSMutableData *mutableData;
@property (nonatomic) NSHTTPURLResponse *lastResponse;
@property (nonatomic) NSError *error;
@property (nonatomic) NSFileHandle *fileHandleForWriting;
@property (nonatomic, getter=isStarted) BOOL started;
@property (nonatomic, getter=isCancelled) BOOL cancelled;
@property (nonatomic, getter=isFinished) BOOL finished;
@property(nonatomic) BOOL didConnect;
@property(nonatomic) BOOL shouldShowActivityIndicator;
@property(nonatomic) NSMutableDictionary* userDictionary;
- (void) log:(NSString*)msg;
- (void) logError:(NSError*)error;
- (void) prepareFileHandleIfNeeded;
- (void) resetFileHandle;
- (void) connection:(NSURLConnection*)aConnection didFailWithError:(NSError*)anError;
- (void) didFinishLoading;
- (void) didFailWithError:(NSError*)error;
- (void) cleanup;
@end


@implementation PHTTPConnection


#pragma mark Factory

+ (id) connectionWithURL:(NSURL*)URL
{
	return [self connectionWithURL:URL delegate:nil];
}

+ (id) connectionWithRequest:(NSURLRequest*)request
{
	return [self connectionWithRequest:request delegate:nil];
}

+ (id) connectionWithURL:(NSURL*)URL delegate:(id<PHTTPConnectionDelegate>)delegate
{
	PHTTPConnection *connection = [[self alloc] init];
	connection.URL = URL;
	connection.delegate = delegate;
	return connection;
}

+ (id) connectionWithRequest:(NSURLRequest*)request delegate:(id<PHTTPConnectionDelegate>)delegate
{
	PHTTPConnection *connection = [[self alloc] init];
	connection.request = request;
	connection.delegate = delegate;
	return connection;
}





#pragma mark Memory

- (void) dealloc {
    self.shouldShowActivityIndicator = NO;
}

- (id) init
{
	if ((self = [super init]))
	{
		self.userDictionary = [NSMutableDictionary dictionary];
        self.SSLTrustedHosts = [[self class] SSLTrustedHosts];
	}
	return self;
}

- (NSData *)data
{
    return self.mutableData;
}

- (void)setData:(NSData *)data
{
    self.mutableData = [data mutableCopy];
}

- (void) setConnection:(NSURLConnection *)connection
{
    if (connection != _connection)
    {
        [_connection cancel];
        _connection = connection;
        _shouldShowActivityIndicator = (self.connection && !self.doNotShowActivityIndicator);
    }
}

- (void) setDoNotShowActivityIndicator:(BOOL)flag
{
    _doNotShowActivityIndicator = flag;
    self.shouldShowActivityIndicator = (self.connection && !self.doNotShowActivityIndicator);
}

- (void) setShouldShowActivityIndicator:(BOOL)flag
{
    if (_shouldShowActivityIndicator != flag) {
        if (flag && !_shouldShowActivityIndicator)
        {
            [PHTTPConnectionNetworkActivityStack push];
        } else if (!flag && _shouldShowActivityIndicator)
        {
            [PHTTPConnectionNetworkActivityStack pop];
        }
        _shouldShowActivityIndicator = flag;
    }
}


#pragma mark API


- (BOOL)executing
{
    return (self.isStarted && !self.isFinished);
}

- (BOOL)isExecuting
{
    return (self.isStarted && !self.isFinished);
}

- (void)  start
{
    if (self.isStarted) {
        return;
    }
    if (self.isFinished) {
        return;
    }
    
    self.started = YES;
    
	if (self.targetFileURL)
	{
		[self prepareFileHandleIfNeeded];
	}
    
    if (!self.request && self.URL)
    {
        if ([self.delegate respondsToSelector:@selector(HTTPConnection:requestForURL:)]) {
            self.request = [self.delegate HTTPConnection:self requestForURL:self.URL];
            NSAssert(self.request, @"Delegate did not return any HTTPRequest for URL %@", self.URL);
        } else {
            self.request = [NSURLRequest requestWithURL:self.URL];
        }
    }
    if (!self.URL) self.URL = [self.request URL];
    
	if (self.byteOffset > 0)
	{
		NSMutableURLRequest* mutableRequest = [self.request mutableCopy];
		[mutableRequest setValue:[NSString stringWithFormat:@"bytes=%u-", (uint32_t)self.byteOffset] forHTTPHeaderField:@"Range"];
		self.request = mutableRequest;
	}
	
    NSAssert(self.request || self.URL, @"HTTPConnection: either URL or request property should be present");
    
    [self connect];
}

- (void) startWithCompletionBlock:(void(^)(void))aBlock
{
	self.completionBlock = aBlock;
	[self start];
}

- (void) cancel
{
    if (self.isFinished) {
        return;
    }
    
    self.cancelled = YES;
    self.mutableData = nil;
    self.error = nil;
    [self finish];
}

- (double) loadingProgress
{
	NSData* aData = self.mutableData;
	NSHTTPURLResponse* response = self.lastResponse;
    
	if (aData && response && [response expectedContentLength] != NSURLResponseUnknownLength)
	{
		float contentLength = (float)[response expectedContentLength];
		if (contentLength <= 0) return (float)0.0;
		contentLength += (float)self.byteOffset;
		
		float dataLength = (float)[aData length] + self.byteOffset;
		if (self.fileHandleForWriting)
		{
			dataLength = (float)[self.fileHandleForWriting offsetInFile];
		}
		
		if (contentLength > 0.001)
		{
			return dataLength / contentLength;
		}
	}
	return (float)0.0;
}

- (NSURLRequest*) willSendInitialRequest:(NSURLRequest*)aRequest;
{
    return aRequest;
}

- (void)finish
{
    if (self.isFinished) {
        return;
    }
    
    self.finished = YES;
    if (self.completionBlock) self.completionBlock();
    [self didFinish];
    [self cleanup];
}

- (void) didFinish
{
}

#pragma mark PHTTPConnection implementation



- (NSURLRequest*) willSendRequest:(NSURLRequest*)aRequest redirectResponse:(NSURLResponse*)aResponse
{
    return aRequest;
}

- (NSInputStream*) needNewBodyStream:(NSURLRequest*)aRequest
{
    return NULL;
}

- (BOOL) canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace*)aProtectionSpace
{
    NSString *authenticationMethod = aProtectionSpace.authenticationMethod;
    if ([authenticationMethod isEqual:NSURLAuthenticationMethodHTTPBasic]) {
        return YES;
    }
    if ([authenticationMethod isEqual:NSURLAuthenticationMethodHTTPDigest]) {
        return YES;
    }
    if ([authenticationMethod isEqual:NSURLAuthenticationMethodServerTrust]) {
        return YES;
    }
    return NO;
}

- (void) didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)aChallenge
{
    if ([aChallenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust] && [self.SSLTrustedHosts containsObject:aChallenge.protectionSpace.host])
    {
        [aChallenge.sender useCredential:[NSURLCredential credentialForTrust:aChallenge.protectionSpace.serverTrust] forAuthenticationChallenge:aChallenge];
        return;
    }
    
    if (self.username && self.password)
    {
        if (([aChallenge previousFailureCount] == 0))
        {
            NSURLCredential* credential = [NSURLCredential credentialWithUser:self.username 
                                                                     password:self.password
                                                                  persistence:NSURLCredentialPersistenceNone];
            [[aChallenge sender] useCredential:credential forAuthenticationChallenge:aChallenge];
        }
        else
        {
            [[aChallenge sender] cancelAuthenticationChallenge:aChallenge];
        }
        
        return;
    }

    [[aChallenge sender] continueWithoutCredentialForAuthenticationChallenge:aChallenge];
}

- (void) didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge*)aChallenge
{
}

- (BOOL) shouldUseCredentialStorage
{
    return YES;
}

// Note: this method is called once per mime type; it should reset received data appropriately
- (void) didReceiveResponse:(NSURLResponse*)aResponse
{
	self.lastResponse = (NSHTTPURLResponse*)aResponse;
	
	NSDictionary* headers = [self.lastResponse allHeaderFields];
    
	if (self.mutableData != nil)
	{
		[self log:@"didReceiveResponse: data is not nil => multipart connection detected; resetting data"];
		[self resetFileHandle];
	}
	
	if (!headers[@"Accept-Ranges"])
	{
		self.byteOffset = 0;
		[self resetFileHandle];
	}
	
    self.mutableData = [NSMutableData data];
}

- (void) didReceiveData:(NSData*)aData
{
	if (self.fileHandleForWriting)
	{
		[self.fileHandleForWriting writeData:aData];
	}
	else
	{
        [self.mutableData appendData:aData];
	}
}

- (void) didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
}

- (void) didFinishLoading
{
}

- (void) didFailWithError:(NSError*)anError
{
    if ([anError code] != 404)
    {
        NSLog(@"%@ didFailWithError: %@", [self class], anError);
    }
    // forget data
    self.mutableData = nil;
    self.error = anError;
}

- (void) connect
{
    self.request = [self willSendInitialRequest:self.request];
    self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
    
    NSAssert([NSRunLoop currentRunLoop], @"[NSRunLoop currentRunLoop] is nil");
    
    if (self.runLoopMode)
    {
        // NSRunLoopCommonModes includes UITrackingRunLoopMode
        
        // This mode makes notification happen while user is scrolling
        [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:self.runLoopMode]; 
    }
    else
    {
        // This mode makes notification happen when user stopped scrolling
        [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode]; // use default mode if not a modern OS
    }
    
    [self.connection start];
    self.didConnect = YES;
}

- (void) cleanup
{
    self.connection = nil;
	self.mutableData = nil;
    self.completionBlock = nil;     // this will clear the cycle if the block references this connection
	
	[self.fileHandleForWriting closeFile];
	self.fileHandleForWriting = nil;
}

- (NSCachedURLResponse*) willCacheResponse:(NSCachedURLResponse*)aCachedResponse
{
    return aCachedResponse;
}





#pragma mark NSURLConnection delegate



- (NSURLRequest*) connection:(NSURLConnection*)aConnection willSendRequest:(NSURLRequest*)aRequest redirectResponse:(NSURLResponse*)aRedirectResponse
{
    if ([self.delegate respondsToSelector:@selector(HTTPConnection:willSendRequest:redirectResponse:)])
        return [self.delegate HTTPConnection:self willSendRequest:aRequest redirectResponse:aRedirectResponse];
    else
        return [self willSendRequest:aRequest redirectResponse:aRedirectResponse];
}

- (NSInputStream*) connection:(NSURLConnection*)aConnection needNewBodyStream:(NSURLRequest*)aRequest
{
    if ([self.delegate respondsToSelector:@selector(HTTPConnection:needNewBodyStream:)])
        return [self.delegate HTTPConnection:self needNewBodyStream:aRequest];
    else
        return [self needNewBodyStream:aRequest];  
}

- (BOOL) connection:(NSURLConnection*)aConnection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace*)aProtectionSpace
{
    if ([self.delegate respondsToSelector:@selector(HTTPConnection:canAuthenticateAgainstProtectionSpace:)])
        return [self.delegate HTTPConnection:self canAuthenticateAgainstProtectionSpace:aProtectionSpace];
    else
        return [self canAuthenticateAgainstProtectionSpace:aProtectionSpace];
}

- (void) connection:(NSURLConnection*)aConnection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)aChallenge
{
    if ([self.delegate respondsToSelector:@selector(HTTPConnection:didReceiveAuthenticationChallenge:)])
        [self.delegate HTTPConnection:self didReceiveAuthenticationChallenge:aChallenge];
    else
        [self didReceiveAuthenticationChallenge:aChallenge];
}

- (void) connection:(NSURLConnection*)aConnection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge*)aChallenge
{
    if ([self.delegate respondsToSelector:@selector(HTTPConnection:didCancelAuthenticationChallenge:)])
        [self.delegate HTTPConnection:self didCancelAuthenticationChallenge:aChallenge];
    else
        [self didCancelAuthenticationChallenge:aChallenge];
}

- (BOOL) connectionShouldUseCredentialStorage:(NSURLConnection*)aConnection
{
    if ([self.delegate respondsToSelector:@selector(HTTPConnectionShouldUseCredentialStorage:)])
        return [self.delegate HTTPConnectionShouldUseCredentialStorage:self];
    else
        return [self shouldUseCredentialStorage];
}

// Note: this method is called once per mime type; it should reset received data appropriately
- (void) connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)aResponse
{
    [self didReceiveResponse:aResponse];
    if ([self.delegate respondsToSelector:@selector(HTTPConnection:didReceiveResponse:)])
        [self.delegate HTTPConnection:self didReceiveResponse:aResponse];
}

- (void) connection:(NSURLConnection*)aConnection didReceiveData:(NSData*)aData
{
    [self didReceiveData:aData];
    if ([self.delegate respondsToSelector:@selector(HTTPConnection:didReceiveData:)])
        [self.delegate HTTPConnection:self didReceiveData:aData];
}

- (void) connection:(NSURLConnection*)aConnection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    [self didSendBodyData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    if ([self.delegate respondsToSelector:@selector(HTTPConnection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:)])
        [self.delegate HTTPConnection:self didSendBodyData:bytesWritten 
                    totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}

- (void) connectionDidFinishLoading:(NSURLConnection*)aConnection
{
    if (self.lastResponse)
    {
        NSInteger code = [self.lastResponse statusCode];
        if (code < 200 || code > 399) // do not report redirection codes as errors
        {
            NSError* anError = [NSError errorWithDomain:PHTTPConnectionErrorDomain
                                                   code:code
                                               userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTable(@"The operation could not be completed (server error %d: %@).", @"PHTTPConnection", nil), code, [NSHTTPURLResponse localizedStringForStatusCode:code]],
                                                         PHTTPConnectionErrorResponseBodyDataKey: self.data}];
            [self connection:aConnection didFailWithError:anError];
            return;
        }
    }
    
    [self didFinishLoading];
    if ([self.delegate respondsToSelector:@selector(HTTPConnectionDidFinishLoading:)])
        [self.delegate HTTPConnectionDidFinishLoading:self];
    
    [self finish];
}

- (void) connection:(NSURLConnection*)aConnection didFailWithError:(NSError*)anError
{
    [self didFailWithError:anError];
    if ([self.delegate respondsToSelector:@selector(HTTPConnection:didFailWithError:)])
        [self.delegate HTTPConnection:self didFailWithError:anError];
    
    [self finish];
}

- (NSCachedURLResponse*) connection:(NSURLConnection*)aConnection willCacheResponse:(NSCachedURLResponse*)aCachedResponse
{
    if ([self.delegate respondsToSelector:@selector(HTTPConnection:willCacheResponse:)])
        return [self.delegate HTTPConnection:self willCacheResponse:aCachedResponse];
    else
        return [self willCacheResponse:aCachedResponse];  
}





#pragma mark NSCoding



- (id)initWithCoder:(NSCoder*)coder 
{
    self = [super init];
    self.URL      = [coder decodeObjectForKey:@"url"];  // @"url" is lower case for binary compatibility with Patryst
    self.request  = [coder decodeObjectForKey:@"request"];
    self.username = [coder decodeObjectForKey:@"username"];
    self.password = [coder decodeObjectForKey:@"password"];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:self.URL      forKey:@"url"];  // @"url" is lower case for binary compatibility with Patryst
    [coder encodeObject:self.request  forKey:@"request"];
    [coder encodeObject:self.username forKey:@"username"];
    [coder encodeObject:self.password forKey:@"password"];
}





#pragma mark Logging


- (void) log:(NSString*)msg
{
    NSLog(@"%@[%@]: %@", self, [[self.request URL] absoluteString], msg);
}

- (void) logError:(NSError*)anError
{
    [self log:[anError localizedDescription]];
}

- (void) prepareFileHandleIfNeeded
{
	if (self.fileHandleForWriting) return;
	
	if (!self.targetFileURL)
	{
		[self log:@"ERROR: targetFileURL is nil!"];
		return;
	}
	
	if (![self.targetFileURL isFileURL])
	{
		[self log:@"ERROR: targetFileURL is not a file URL!"];
		return;
	}
	
	NSString* filePath = [self.targetFileURL path];
	
	if (!filePath)
	{
		[self log:@"ERROR: [targetFileURL path] returned nil!"];
		return;
	}
    
	NSString* directoryPath = [filePath stringByDeletingLastPathComponent];
	NSError* theError = nil;
	NSFileManager* fm = [[NSFileManager alloc] init];
	if ([fm createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&theError])
	{
		if (![fm fileExistsAtPath:filePath])
		{
			[fm createFileAtPath:filePath contents:[NSData data] attributes:nil];
		}
		
		NSDictionary* attributes = [fm attributesOfItemAtPath:filePath error:&theError];
		if (attributes)
		{
			self.byteOffset = [attributes fileSize];
		}
		else
		{
			[self logError:theError];
			return;
		}
		
		self.fileHandleForWriting = [NSFileHandle fileHandleForWritingAtPath:filePath];
		[self.fileHandleForWriting seekToEndOfFile]; // works in all cases: either the file is empty, or has some data.
	}
	else
	{
		[self logError:theError];
	}
}

- (void) resetFileHandle
{
	if (!self.fileHandleForWriting) return;
	if (!self.targetFileURL) return;
	
	[self.fileHandleForWriting closeFile];
	self.fileHandleForWriting = nil;
    
	NSError* theError = nil;
	if (![[NSFileManager defaultManager] removeItemAtURL:self.targetFileURL error:&theError])
	{
		[self logError:theError];
	}
    
	[self prepareFileHandleIfNeeded];
}


@end
