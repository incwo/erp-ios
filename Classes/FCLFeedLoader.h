@class PFeed;
@interface FCLFeedLoader : NSObject

- (void) loadFeedWithURL:(NSURL*)feedURL completion:(void(^)(PFeed*, NSError*))block;
- (void) cancel;

@end
