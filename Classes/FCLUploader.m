#import "FCLUploader.h"
#import "FCLUpload.h"

#import "OAHTTPQueue.h"
#import "OAHTTPDownload.h"

static FCLUploader* sharedUploader;
@implementation FCLUploader

@synthesize delegate;

@synthesize queue;

- (NSString*) queueArchivePath
{
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
            stringByAppendingPathComponent:@"queue.archive"];
}

- (void) start
{
    self.queue = [NSKeyedUnarchiver unarchiveObjectWithFile:[self queueArchivePath]];
    if (!self.queue) self.queue = [[OAHTTPQueue alloc] init];
    self.queue.delegate = self;
    
    [self.delegate uploaderDidUpdateStatus:self];
}

- (void) stop
{
    [self.delegate uploaderDidUpdateStatus:self];
    
    [self.queue pushPause];
    self.queue.delegate = nil;
    [NSKeyedArchiver archiveRootObject:self.queue toFile:[self queueArchivePath]];
    self.queue = nil;
}

- (void) addUpload:(FCLUpload*)upload
{
    [self.queue appendDownload:[upload OAHTTPDownload]];
    [self.delegate uploaderDidUpdateStatus:self];
}

- (BOOL) isUploading
{
    if ([self.queue currentDownload])
    {
        return YES;
    }
    return NO;
}





#pragma mark OAHTTPDownloadDelegate

- (void) oadownloadDidFinishLoading:(id<OAHTTPDownloadProtocol>)download
{
    NSString *dataString = [[NSString alloc] initWithData:[download receivedData] encoding:NSUTF8StringEncoding];
    NSLog(@"Finished. Received data: %@", dataString);
    [self.delegate uploaderDidUpdateStatus:self];
}

- (void) oadownload:(id<OAHTTPDownloadProtocol>)download didFailWithError:(NSError*)error
{
    NSLog(@"ERROR: OAHTTPDownload: %@", [error localizedDescription]);
    [self.delegate uploader:self didFailWithError:error];
    if ([self.queue isNetworkError:error])
    {
        NSLog(@"isNetworkError => resetting download and appending to the queue once again");
        [download reset];
        [self.queue appendDownload:download];
    }
    [self.delegate uploaderDidUpdateStatus:self];
}

#pragma mark sharedUploader


+ (FCLUploader*) sharedUploader
{
    if (!sharedUploader)
    {
        sharedUploader = [[self alloc] init];
    }
    return sharedUploader;
}

+ (void) releaseSharedUploader
{
    sharedUploader = nil;
}




@end
