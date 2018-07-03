//  IGFeedItem
//
//

@class OAXMLDecoder;
@class PFeed, PFeedItemEnclosure;

@interface PFeedItem : NSObject<NSCoding>

@property(nonatomic) NSString *guid; // URI
@property(nonatomic) NSString *title;
@property(nonatomic) NSString *htmlDescription; // HTML description
@property(nonatomic) NSString *textDescription; // Text description
@property(nonatomic) NSString *htmlFulltext; // Text description
@property(nonatomic) NSString *textFulltext; // Text description
@property(nonatomic) NSString *podcastHTMLDescription;
@property(nonatomic) NSString *category;
@property(nonatomic) NSString *author;
@property(nonatomic) NSString *authorName;
@property(nonatomic) NSString *sourceName;
@property(nonatomic) NSString *categoryName;
@property(nonatomic) NSString *legend;
@property(nonatomic) NSDate *pubDate;
@property(nonatomic) NSURL *linkURL;
@property(nonatomic) NSURL *imageURL;
@property(nonatomic) NSArray *enclosures;
@property(nonatomic) NSArray *thumbnails;
@property(nonatomic, getter=isHidden) BOOL hidden;
@property(nonatomic, getter=isRead) BOOL read;
@property(nonatomic) NSNumber *movieRatingNumber;

@property(nonatomic) PFeed *feed;

+ (PFeedItem *) feedItem;
- (PFeedItem *) validFeedItemAfterParsingForMinimumAllowedDate:(NSDate *)minimumAllowedDate;	// minimumAllowedDate can be nil (ignored)
- (void) decodeWithRSSDecoder:(OAXMLDecoder*)decoder forFeed:(PFeed*)aFeed;

- (NSArray *) enclosuresWithTypeMatching:(NSString *)mimeTypeSubstring;
- (PFeedItemEnclosure *) enclosureWithTypeMatching:(NSString*)mimeTypeSubstring;
- (PFeedItemEnclosure *) downloadableEnclosure;
- (BOOL) shouldSurviveAutoRemoval;

@end


@interface PFeedItem(Formatting)

@property(nonatomic, readonly) NSNumber *nativeImageWidthNumber;
@property(nonatomic, readonly) NSNumber *nativeImageHeightNumber;
@property(nonatomic, readonly) NSString *nativeImageLegend;
@property(nonatomic, readonly) NSURL *nativeImageURL;
@property(nonatomic, readonly) NSURL *nativeVideoURL;
@property(nonatomic, readonly) NSURL *nativeAudioURL;
@property(nonatomic, readonly) NSURL *videoIframeURL;
@property(nonatomic, readonly) NSString *durationFormatted;

@end


