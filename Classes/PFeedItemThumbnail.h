//
//  PFeedItemThumbnail.h
//
//

#import <Foundation/Foundation.h>

@class OAXMLDecoder, PFeed;
@interface PFeedItemThumbnail : NSObject<NSCoding>

@property(nonatomic) NSInteger width;
@property(nonatomic) NSInteger height;
@property(nonatomic) NSURL *URL;
- (void) decodeWithDecoder:(OAXMLDecoder *)decoder forFeed:(PFeed *)aFeed;
- (PFeedItemThumbnail *) validThumbnail;

@end
