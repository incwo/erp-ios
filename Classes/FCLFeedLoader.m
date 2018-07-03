#import "FCLFeedLoader.h"
#import "OAXMLDecoder.h"
#import "PFeed.h"
#import "PFeedItem.h"
#import "PHTTPConnection.h"

@interface FCLFeedLoader ()
@property PHTTPConnection *connection;

@end

@implementation FCLFeedLoader

- (void) loadFeedWithURL:(NSURL*)URL completion:(void(^)(PFeed*, NSError*))completionBlock
{
    if (self.connection)
    {
        @throw [NSException exceptionWithName:@"FCLFeedLoader: Cannot load twice using the same feed loader" reason:@"" userInfo:nil];
        return;
    }
    
    if (!URL)
    {
        completionBlock(nil, nil);
        return;
    }



//    PFeed *cachedFeed = [self.feedCache objectForKey:URL];
//    if (cachedFeed) {
//        if (completionBlock) completionBlock(NO, cachedFeed, YES, nil);
//        // make sure completionBlock is not called again with cached data
//        [self.feedURLCache forgetDataForURL:URL];
//    }
    
    PHTTPConnection* connection = [PHTTPConnection connectionWithURL:URL]; // cache:self.feedURLCache];
    self.connection = connection;
    __typeof(self) __weak weakSelf = self;
    connection.completionBlock = ^{
        if (weakSelf.connection.isCancelled)
        {
            completionBlock(nil, nil);
            return;
        }
        
        NSData *data = weakSelf.connection.data;
        if (!data)
        {
            if (completionBlock) completionBlock(nil, weakSelf.connection.error);
            return;
        }
        
        NSData* xmlData = [data copy];
        
        if ([xmlData length] == 0)
        {
            // Silently fail
            if (completionBlock) completionBlock(nil, nil);
            return;
        }
        
        PFeed* loadedFeed = [[PFeed alloc] init];
        loadedFeed.URL = URL;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            OAXMLDecoder* xmlDecoder = [OAXMLDecoder parseData:xmlData withBlock:^(OAXMLDecoder *parser) {
                [loadedFeed decodeFeedRSSWithDecoder:parser];
            }];
            
            NSError* error = xmlDecoder.error;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error)
                {
//                    // we don't want to cache unparseable date
//                    [self.feedCache removeObjectForKey:URL];
//                    [self.feedURLCache forgetDataForURL:URL];
                    
                    if (completionBlock) completionBlock(nil, error);
                    weakSelf.connection = nil;
                }
                else
                {
                    if (completionBlock) completionBlock(loadedFeed, nil);
//                    [self.feedCache setObject:loadedFeed forKey:URL];
//                    [NSKeyedArchiver archiveRootObject:self.feedCache toFile:self.feedCachePath];
                    weakSelf.connection = nil;
                }
            });
        });
    };
    [_connection start];
}

- (void) cancel
{
    if (_connection)
    {
        [_connection cancel];
        _connection = nil;
    }
}

@end
