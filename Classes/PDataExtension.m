//
//  PDataExtension.m

//
//

#import "PDataExtension.h"

NSMutableSet* gPAsyncDataDownloaders = nil;

@interface PAsyncDataDownloader : NSObject
{
	NSObject<PAsynchronousDataDelegate>* delegate;
	NSMutableData* data;
	NSURL* url;
	NSURLConnection* connection;
	NSInteger statusCode;
}
@property(retain) NSObject<PAsynchronousDataDelegate>* delegate;
@property(retain) NSMutableData* data;
@property(retain) NSURLConnection* connection;
@property(retain) NSURL* url;
- (id) initWithURLRequest:(NSURLRequest*)req delegate:(NSObject<PAsynchronousDataDelegate>*)theDelegate;
@end

@implementation PAsyncDataDownloader
@synthesize delegate, data, url, connection;

- (id) initWithURLRequest:(NSURLRequest*)req delegate:(NSObject<PAsynchronousDataDelegate>*)theDelegate
{
	if ((self = [super init]))
	{
		self.delegate = theDelegate;
		self.url = [req URL];
		NSURLConnection* theConnection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
		self.connection = theConnection;
	}
	return self;
}

- (void)download
{
	if (gPAsyncDataDownloaders == nil)
		gPAsyncDataDownloaders = [[NSMutableSet alloc] initWithCapacity:8];
	[gPAsyncDataDownloaders addObject:self];
	[self.connection start];
}


#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)receivedData
{
	if (self.data == nil)
		self.data = [NSMutableData dataWithCapacity:2 * receivedData.length];
		
	[self.data appendData:receivedData];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if ([self.delegate respondsToSelector:@selector(connectionForURL:didReceiveAuthenticationChallenge:)])
		[self.delegate connectionForURL:self.url didReceiveAuthenticationChallenge:challenge];
	else
		[[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	statusCode = [(NSHTTPURLResponse*)response statusCode];
	if (self.data == nil && statusCode == 200)
	{
		NSUInteger dataSize = [[(NSHTTPURLResponse*)response allHeaderFields][@"Content-Size"] unsignedIntValue];
		if (dataSize > 0)
			self.data = [NSMutableData dataWithCapacity:dataSize];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if ([self.delegate respondsToSelector:@selector(data:didDownloadFromURL:withError:httpStatusCode:)])
		[self.delegate data:nil didDownloadFromURL:self.url withError:error httpStatusCode:statusCode];
	else
		[self.delegate data:nil didDownloadFromURL:self.url withError:error];
	[gPAsyncDataDownloaders removeObject:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if ([self.delegate respondsToSelector:@selector(data:didDownloadFromURL:withError:httpStatusCode:)])
		[self.delegate data:self.data didDownloadFromURL:self.url withError:nil httpStatusCode:statusCode];
	else
		[self.delegate data:self.data didDownloadFromURL:self.url withError:nil];
	[gPAsyncDataDownloaders removeObject:self];
}

@end


@implementation NSData(PDataExtension)
+ (void) downloadFromURL:(NSURL*)url delegate:(NSObject<PAsynchronousDataDelegate>*)delegate
{
	[NSData downloadWithURLRequest:[NSURLRequest requestWithURL:url] delegate:delegate];
}

+ (void) downloadWithURLRequest:(NSURLRequest*)request delegate:(NSObject<PAsynchronousDataDelegate>*)delegate
{
	PAsyncDataDownloader* downloader = [[PAsyncDataDownloader alloc] initWithURLRequest:request delegate:delegate];
	[downloader download];
}

- (NSString*) hexString
{
	NSMutableString *stringBuffer = [NSMutableString
stringWithCapacity:([self length] * 2)];
	const unsigned char *dataBuffer = [self bytes];
	int i;
	
	for (i = 0; i < [self length]; ++i)
		[stringBuffer appendFormat:@"%02X", (unsigned int)dataBuffer[ i ]];
	
	return [stringBuffer copy];
}


@end
