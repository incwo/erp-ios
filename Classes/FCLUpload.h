@class OAHTTPDownload;
@class FCLSession;

@interface FCLUpload : NSObject

@property(nonatomic,strong) NSString* fileId;
@property(nonatomic,strong) NSString* categoryKey;
@property(nonatomic,strong) UIImage* image;
@property(nonatomic,strong) NSArray* fields;

@property(nonatomic,strong) FCLSession *session;

- (OAHTTPDownload *) OAHTTPDownload;

@end
