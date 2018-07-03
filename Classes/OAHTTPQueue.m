#import "OAHTTPQueue.h"
#import "OANetworkActivityIndicator.h"

@interface OAHTTPQueue ()
- (void) finishAndProceed;
@end


@implementation OAHTTPQueue {
    NSInteger pauseStack;
}
@synthesize queue, decodingQueue, currentDownload, delegate, downloadDelegate;

- (void) reset
{
    self.queue = nil;
    [self.decodingQueue cancelAllOperations];
    self.decodingQueue = nil;
    self.currentDownload = nil;
    self.delegate = nil;
    self.downloadDelegate = nil;
    pauseStack = 0;
}

- (id) init
{
    if (self = [super init])
    {
        [self reset];
		self.queue = [[NSMutableArray alloc] init];
        [self proceed];
	}
	return self;
}

- (void)dealloc
{
    [self cancelAllDownloads];
    [self reset];
}



#pragma mark NSCoding


- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    [self reset];
    self.queue = [coder decodeObjectForKey:@"queue"];
    id download = [coder decodeObjectForKey:@"currentDownload"];
    if (download)
    {
        NSLog(@"OAHTTPQueue: decoded non-empty queue; currentDownload: %@", download);
        [self.queue insertObject:download atIndex:0];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    if ((queue && [queue count] > 0) || currentDownload)
    {
        NSLog(@"OAHTTPQueue: encoding non-empty queue");
    }
    [coder encodeObject:queue forKey:@"queue"];
    [coder encodeObject:currentDownload forKey:@"currentDownload"];
}


#pragma mark Adding downloads to the queue


- (void) appendDownload:(id<OAHTTPDownload>) download
{
    [queue addObject:download];
    [self proceed];
}

- (void) prependDownload:(id<OAHTTPDownload>) download
{
    [queue insertObject:download atIndex:0];
    [self proceed];
}

- (void) appendDownloadOnce:(id<OAHTTPDownload>) download
{
    if (![queue containsObject:download] && ![currentDownload isEqual:download])
    {
        [self appendDownload:download];
    }
}

- (void) prependDownloadOnce:(id<OAHTTPDownload>) download
{
    if (![queue containsObject:download] && ![currentDownload isEqual:download])
    {
        [self prependDownload:download];
    }
}

- (void) appendDownloadOnce:(id<OAHTTPDownload>) download withStackLimit:(NSUInteger)limit
{
    [queue removeObject:download];
    [self appendDownloadOnce:download];
    
    // Note: usually this loop will have only one iteration, so this would be very efficient
    while ([queue count] > limit)
    {
        [queue removeObjectAtIndex:0];
    }
}

- (void) prependDownloadOnce:(id<OAHTTPDownload>) download withStackLimit:(NSUInteger)limit
{
    [queue removeObject:download];
    [self prependDownloadOnce:download];
    
    // Note: usually this loop will have only one iteration, so this would be very efficient
    while ([queue count] > limit)
    {
        [queue removeLastObject];
    }
}

- (void) removeDownload:(id<OAHTTPDownload>) download
{
    [queue removeObject:download];
    if ([currentDownload isEqual:download])
    {
        [self cancelCurrentDownload];
        // in case the queue was not started, there's no currentDownload, so it is safe to proceed here
        [self proceed];
    }
}

- (void) cancelCurrentDownload
{
    [self.currentDownload cancel];
    self.currentDownload = nil;
}

- (void) cancelAllDownloads
{
    [self cancelCurrentDownload];
    [queue removeAllObjects];
}


#pragma mark Pause

- (void) pushPause
{
    pauseStack++;
}

- (void) popPause
{
    pauseStack--;
    if (pauseStack == 0) // just resumed
    {
        [self proceed];
    }
}



#pragma mark Info

- (NSData*) receivedData
{
    return self.currentDownload.receivedData;
}

// FIXME: should this be defined here?
- (BOOL) isNetworkError:(NSError*)error
{
    NSInteger errorCode = [error code];
    return (errorCode == NSURLErrorDNSLookupFailed ||
            errorCode == NSURLErrorCannotFindHost ||
            errorCode == NSURLErrorCannotConnectToHost ||
            errorCode == NSURLErrorNotConnectedToInternet ||
            errorCode == NSURLErrorInternationalRoamingOff);
}



#pragma mark Private routines


- (void) setCurrentDownload:(id<OAHTTPDownload>)download
{
    if (downloadDelegate) currentDownload.delegate = nil;
    currentDownload.queue = nil;
    currentDownload = download;
    currentDownload.queue = self;
    if (downloadDelegate) currentDownload.delegate = downloadDelegate;
}

// This method starts a new request if no request is currently processed.
// Does nothing if there are no requests in the queue.
- (void) proceed
{
    if (pauseStack < 1 && [queue count] > 0)
    {
        if (!currentDownload)
        {
            self.currentDownload = [queue objectAtIndex:0];
            [queue removeObjectAtIndex:0];
            [self.currentDownload start];
        }
        else
        {
        }
    }
}

- (void) finishAndProceed
{
    // push/pop is done to avoid indicator flickering on cancel/proceed
    [OANetworkActivityIndicator push];
    [self cancelCurrentDownload];
    [self proceed];
    [OANetworkActivityIndicator pop];
}



#pragma mark OAHTTPDownloadDelegate

// For more callbacks user should set downloadDelegate
- (void) oadownloadDidFinishLoading:(id<OAHTTPDownload>)download
{
    [self.delegate oadownloadDidFinishLoading:download];
    [self finishAndProceed];
}

- (void) oadownload:(id<OAHTTPDownload>)download didFailWithError:(NSError *)error
{
    [self.delegate oadownload:download didFailWithError:error];
    [self finishAndProceed];
}



#pragma mark NSOperationQueue


- (void) addOperation:(NSOperation*)op
{
    if (!self.decodingQueue)
    {
        self.decodingQueue = [NSOperationQueue new];
        [self.decodingQueue setMaxConcurrentOperationCount:1];
    }
    
    [self.decodingQueue addOperation:op];
}

@end
