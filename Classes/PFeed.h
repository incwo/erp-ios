//
//  IGFeed
//
//

@class OAXMLDecoder;

@interface PFeed : NSObject<NSCoding>

@property (nonatomic) NSArray *items;
@property (nonatomic, readonly) NSUInteger unreadCount;
@property (nonatomic) NSDate *updateDate;
@property (nonatomic) NSError *error;
@property (nonatomic) NSString *uid;
@property (nonatomic) NSURL *URL;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *description;
@property (nonatomic) NSString *copyright;
@property (nonatomic) NSURL *primarySiteURL;
@property (nonatomic) NSURL *imageURL;
@property(nonatomic) BOOL displayPreviewImage;
- (void) updateUnreadCount;
- (void) decodeFeedWithDecoder:(OAXMLDecoder *)decoder;
- (void) decodeFeedRSSWithDecoder:(OAXMLDecoder *)decoder;

@end
