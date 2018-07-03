//
//  IGFeedItem
//
//

@class PFeed;
@class OAXMLDecoder;

extern NSString* const LIFeedItemEnclosureStatusNotLoaded;
extern NSString* const LIFeedItemEnclosureStatusLoading;
extern NSString* const LIFeedItemEnclosureStatusLoaded;

@interface PFeedItemEnclosure : NSObject<NSCoding> 

@property(nonatomic) NSString *type;
@property(nonatomic) NSURL *URL;
@property(nonatomic) NSString *status;
@property(nonatomic) NSURL *localURL;
@property(nonatomic, readonly) NSURL *localOrRemoteURL;
@property(nonatomic) NSNumber *widthNumber;
@property(nonatomic) NSNumber *heightNumber;
@property(nonatomic) NSString *legend;
@property(nonatomic) NSUInteger length;
@property(nonatomic) NSTimeInterval duration;
@property(nonatomic) float downloadProgress;

+ (PFeedItemEnclosure *) enclosure;

- (PFeedItemEnclosure *) validEnclosure; // returns valid instance (usually self), or nil if not valid and cannot fix the issues
- (void) decodeWithDecoder:(OAXMLDecoder *)decoder forFeed:(PFeed *)aFeed;

- (void) updateStatus;

- (BOOL) isLoaded;
- (BOOL) isLoading;
- (BOOL) isNotLoaded;

@end
